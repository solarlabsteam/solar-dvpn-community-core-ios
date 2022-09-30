//
//  TunnelsService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit
import NetworkExtension

final public class TunnelsService {
    private(set) var tunnels: [TunnelContainer]
    weak var statusDelegate: TunnelsServiceStatusDelegate?

    private var statusObservationToken: NotificationToken?
    private var awaitingObservationToken: NSKeyValueObservation?
    private var configurationsObservationToken: NotificationToken?

    init(tunnelProviders: [NETunnelProviderManager]) {
        tunnels = tunnelProviders
            .map { TunnelContainer(tunnel: $0) }
            .sorted { TunnelsService.nameIsLess(lhs: $0.name, than: $1.name) }
        startObservingTunnelStatuses()
        startObservingTunnelConfigurations()
    }

    static func nameIsLess(lhs: String, than rhs: String) -> Bool {
        lhs.compare(
            rhs,
            options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive, .numeric]
        ) == .orderedAscending
    }

    func startObservingTunnelConfigurations() {
        configurationsObservationToken = NotificationCenter.default.observe(
            name: .NEVPNConfigurationChange,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                // We schedule reload() in a subsequent runloop to ensure
                // that the completion handler of loadAllFromPreferences
                // is called after the completion handler of the saveToPreferences or removeFromPreferences call,
                // if any, that caused this notification to fire. This notification can also fire
                // as a result of a tunnel getting added or removed outside of the app.
                self?.reload()
            }
        }
    }

    static func create(completionHandler: @escaping (Result<TunnelsService, TunnelsServiceError>) -> Void) {
        NETunnelProviderManager.loadAllFromPreferences() { managers, error in
            guard let managers = managers else {
                if let error = error {
                    log.error("Failed to get tunnel manager: \(String(describing: error))")
                }
                return
            }

            createWireGuard(completionHandler: completionHandler)
        }
    }
    
    static func createWireGuard(
        completionHandler: @escaping (Result<TunnelsService, TunnelsServiceError>) -> Void
    ) {
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            if let error = error {
                log.error("Failed to load tunnel provider managers: \(error)")
                completionHandler(.failure(TunnelsServiceError.loadTunnelsFailed(systemError: error)))
                return
            }

            var tunnelManagers = managers ?? []
            var references: Set<Data> = []
            var tunnelNames: Set<String> = []

            for (index, tunnelManager) in tunnelManagers.enumerated().reversed() {
                if let tunnelName = tunnelManager.localizedDescription {
                    tunnelNames.insert(tunnelName)
                }
                guard let provider = tunnelManager.provider else { continue }

                if provider.migrateConfigurationIfNeeded(with: tunnelManager.localizedDescription ?? "unknown") {
                    tunnelManager.saveToPreferences { _ in }
                }

                if let passwordRef = provider.verifyConfigurationReference() ? provider.passwordReference : nil {
                    references.insert(passwordRef)
                } else {
                    log.info(
                        """
                        Removing orphaned tunnel
                        with non-verifying keychain entry: \(tunnelManager.localizedDescription ?? "<unknown>")
                        """
                        )
                    tunnelManager.removeFromPreferences { _ in }
                    tunnelManagers.remove(at: index)
                }
            }
            Keychain.deleteReferences(except: references)
            completionHandler(.success(TunnelsService(tunnelProviders: tunnelManagers)))
        }
    }

    func add(
        tunnelConfiguration: TunnelConfiguration,
        completionHandler: @escaping (Result<TunnelContainer, TunnelsServiceError>) -> Void
    ) {
        guard let name = tunnelConfiguration.name, !name.isEmpty else {
            completionHandler(.failure(TunnelsServiceError.emptyName))
            return
        }

        guard !tunnels.contains(where: { $0.name == name }) else {
            completionHandler(.failure(TunnelsServiceError.nameAlreadyExists))
            return
        }

        let tunnelProviderManager = NETunnelProviderManager()
        tunnelProviderManager.set(tunnelConfiguration: tunnelConfiguration)
        tunnelProviderManager.isEnabled = true

        let rule = NEOnDemandRuleConnect()
        rule.interfaceTypeMatch = .any

        tunnelProviderManager.onDemandRules = [rule]
        tunnelProviderManager.isOnDemandEnabled = true

        let activeTunnel = tunnels.first { $0.status == .connected || $0.status == .connecting }

        tunnelProviderManager.saveToPreferences { [weak self] error in
            if let error = error {
                log.error( "Add: Saving configuration failed: \(error)")
                tunnelProviderManager.provider?.destroyConfigurationReference()
                completionHandler(.failure(TunnelsServiceError.addTunnelFailed(systemError: error)))
                return
            }

            guard let self = self else { return }

            // Adding a tunnel causes deactivation of any currently active tunnel.
            // This is an hack to reactivate the tunnel that has been deactivated like that.
            if let activeTunnel = activeTunnel {
                if activeTunnel.status == .disconnected || activeTunnel.status == .disconnecting {
                    self.startActivation(of: activeTunnel)
                }
                if activeTunnel.status == .connected || activeTunnel.status == .connecting {
                    activeTunnel.status = .restarting
                }
            }

            let tunnel = TunnelContainer(tunnel: tunnelProviderManager)
            self.tunnels.append(tunnel)
            self.tunnels.sort { TunnelsService.nameIsLess(lhs: $0.name, than: $1.name) }
            completionHandler(.success(tunnel))
        }
    }

    func set(
        onDemandEnabled: Bool,
        for tunnel: TunnelContainer,
        completion: @escaping (Result<TunnelContainer, TunnelsServiceError>) -> Void
    ) {
        let tunnelProviderManager = tunnel.tunnelProvider
        tunnelProviderManager.isOnDemandEnabled = onDemandEnabled
        tunnelProviderManager.isEnabled = true
        tunnelProviderManager.saveToPreferences { error in
            if let error = error {
                log.error("Modify: Saving configuration failed: \(error)")
                completion(.failure(TunnelsServiceError.addTunnelFailed(systemError: error)))
                return
            }

            tunnelProviderManager.loadFromPreferences { error in
                tunnel.isActivateOnDemandEnabled = tunnelProviderManager.isOnDemandEnabled
                if let error = error {
                    log.error("Modify: Re-loading after saving configuration failed: \(error)")
                    completion(.failure(TunnelsServiceError.loadTunnelsFailed(systemError: error)))
                    return
                }
                completion(.success(tunnel))
            }
        }
    }

    func modify(
        tunnel: TunnelContainer,
        tunnelConfiguration: TunnelConfiguration,
        completion: @escaping (Result<TunnelContainer, TunnelsServiceError>) -> Void
    ) {
        guard let name = tunnelConfiguration.name, !name.isEmpty else {
            completion(.failure(TunnelsServiceError.emptyName))
            return
        }

        let tunnelProviderManager = tunnel.tunnelProvider
        tunnelProviderManager.isOnDemandEnabled = true
        tunnelProviderManager.isEnabled = true
        let oldName = tunnelProviderManager.localizedDescription ?? ""
        let isNameChanged = name != oldName
        if isNameChanged {
            guard !tunnels.contains(where: { $0.name == name }) else {
                completion(.failure(TunnelsServiceError.nameAlreadyExists))
                return
            }
            tunnel.name = name
        }

        let isTunnelConfigurationChanged = tunnelProviderManager.tunnelConfiguration != tunnelConfiguration
        if isTunnelConfigurationChanged {
            tunnelProviderManager.set(tunnelConfiguration: tunnelConfiguration)
        }
        tunnelProviderManager.isEnabled = true
        tunnelProviderManager.saveToPreferences { [weak self] error in
            if let error = error {
                log.error("Modify: Saving configuration failed: \(error)")
                completion(.failure(TunnelsServiceError.addTunnelFailed(systemError: error)))
                return
            }

            guard let self = self else { return }
            if isNameChanged {
                self.tunnels.sort { TunnelsService.nameIsLess(lhs: $0.name, than: $1.name) }
            }

            if isTunnelConfigurationChanged {
                if tunnel.status == .connected || tunnel.status == .connecting || tunnel.status == .reasserting {
                    // Turn off the tunnel, and then turn it back on, so the changes are made effective
                    tunnel.status = .restarting
                    (tunnel.tunnelProvider.connection as? NETunnelProviderSession)?.stopTunnel()
                }
            }

            tunnelProviderManager.loadFromPreferences { error in
                tunnel.isActivateOnDemandEnabled = tunnelProviderManager.isOnDemandEnabled
                if let error = error {
                    log.error("Modify: Re-loading after saving configuration failed: \(error)")
                    completion(.failure(TunnelsServiceError.loadTunnelsFailed(systemError: error)))
                    return
                }
                completion(.success(tunnel))
            }
        }
    }

    func startActivation(of tunnel: TunnelContainer) {
        guard tunnels.contains(tunnel) else { return }

        guard tunnel.status == .disconnected else {
            statusDelegate?.activationAttemptFailed(for: tunnel, with: .inactive)
            return
        }

        if let alreadyWaitingTunnel = tunnels.first(where: { $0.status == .waiting }) {
            alreadyWaitingTunnel.status = .disconnected
        }

        if let tunnelInOperation = tunnels.first(where: { $0.status != .disconnected }) {
            log.info("Tunnel '\(tunnel.name)' waiting for deactivation of '\(tunnelInOperation.name)'")
            tunnel.status = .waiting
            activateAwaiting(tunnel: tunnelInOperation)
            if tunnelInOperation.status != .disconnecting {
                startDeactivation(of: tunnelInOperation)
            }
            return
        }

        tunnel.startActivation(statusDelegate: statusDelegate)
    }

    func startActivationOfLastTunnel() {
        guard let tunnel = tunnels.last else { return }
        startActivation(of: tunnel)
    }

    @discardableResult
    func startDeactivationOfActiveTunnel() -> Bool {
        guard let tunnel = tunnels.last, tunnel.status != .disconnected else { return false }
        set(onDemandEnabled: false, for: tunnel) { [weak self] _ in
            self?.startDeactivation(of: tunnel)
        }
        return true
    }

    func startDeactivation(of tunnel: TunnelContainer) {
        tunnel.isAttemptingActivation = false
        guard tunnel.status != .disconnected && tunnel.status != .disconnecting else { return }
        tunnel.startDeactivation(statusDelegate: statusDelegate)
    }

    func refreshStatuses() {
        tunnels.forEach { $0.refreshStatus() }
    }
    
    func removeMultiple(tunnels: [TunnelContainer], completion: @escaping (TunnelsServiceError?) -> Void) {
        // Temporarily pause observation of changes to VPN configurations to prevent the feedback
        // loop that causes `reload()` to be called for each removed tunnel, which significantly
        // impacts performance.
        configurationsObservationToken = nil

        removeMultiple(tunnels: ArraySlice(tunnels)) { [weak self] error in
            completion(error)

            // Restart observation of changes to VPN configrations.
            self?.startObservingTunnelConfigurations()

            // Force reload all configurations to make sure that all tunnels are up to date.
            self?.reload()
        }
    }

    private func removeMultiple(
        tunnels: ArraySlice<TunnelContainer>,
        completion: @escaping (TunnelsServiceError?) -> Void
    ) {
        guard !tunnels.isEmpty else {
            completion(nil)
            return
        }
        
        tunnels.forEach { tunnel in
            remove(tunnel: tunnel) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    func remove(
        tunnel: TunnelContainer,
        completion: @escaping (TunnelsServiceError?) -> Void
    ) {
        let tunnelProviderManager = tunnel.tunnelProvider
        
        (tunnelProviderManager.protocolConfiguration as? NETunnelProviderProtocol)?.destroyConfigurationReference()
        
        tunnelProviderManager.removeFromPreferences { [weak self] error in
            if let error = error {
                log.error("Remove: Saving configuration failed: \(error)")
                completion(TunnelsServiceError.removeTunnelFailed(systemError: error))
                return
            }
            if let self = self, let index = self.tunnels.firstIndex(of: tunnel) {
                self.tunnels.remove(at: index)
            }
            completion(nil)
        }
        
        tunnel.refreshStatus()
    }
}

// MARK: Private

private extension TunnelsService {
    func activateAwaiting(tunnel: TunnelContainer) {
        awaitingObservationToken = tunnel.observe(\.status) { [weak self] tunnel, _ in
            guard let self = self else { return }

            if tunnel.status == .disconnected {
                self.tunnels.first(where: { $0.status == .waiting })?
                    .startActivation(statusDelegate: self.statusDelegate)
                self.awaitingObservationToken = nil
            }
        }
    }

    func startObservingTunnelStatuses() {
        statusObservationToken = NotificationCenter.default.observe(
            name: .NEVPNStatusDidChange,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] statusChangeNotification in
            guard let self = self,
                let session = statusChangeNotification.object as? NETunnelProviderSession,
                let tunnelProvider = session.manager as? NETunnelProviderManager,
                let tunnel = self.tunnels.first(where: { $0.tunnelProvider == tunnelProvider })
            else { return }
            
            let description = tunnel.tunnelProvider.connection.status.description
            log.debug("Tunnel '\(tunnel.name)' status changed to '\(description)'")

            if tunnel.isAttemptingActivation {
                switch session.status {
                case .disconnected:
                    tunnel.isAttemptingActivation = false
                    self.statusDelegate?.activationFailed(
                        for: tunnel,
                        with: .activationAttemptFailed(wasOnDemandEnabled: tunnelProvider.isOnDemandEnabled)
                    )
                case .connected:
                    tunnel.isAttemptingActivation = false
                    self.statusDelegate?.activationSucceeded(for: tunnel)
                default:
                    tunnel.refreshStatus()
                }
            }

            if session.status == .invalid {
                tunnel.isAttemptingActivation = false
                self.statusDelegate?.deactivationSucceeded(for: tunnel)
            }

            guard tunnel.status == .restarting else {
                tunnel.refreshStatus()
                return
            }

            switch session.status {
            case .disconnected:
                tunnel.startActivation(statusDelegate: self.statusDelegate)
            case .connected:
                tunnel.status = .connected
                self.statusDelegate?.activationSucceeded(for: tunnel)
            default:
                return
            }
        }
    }

    func reload() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, _ in
            guard let self = self else { return }
            let loadedTunnelProviders = managers ?? []

            self.tunnels.enumerated().reversed().forEach { index, currentTunnel in
                if !loadedTunnelProviders.contains(where: { $0.isEquivalent(to: currentTunnel) }) {
                    // Tunnel was deleted outside the app
                    self.tunnels.remove(at: index)
                }
            }

            loadedTunnelProviders.forEach { loadedTunnelProvider in
                if let matchingTunnel = self.tunnels.first(where: { loadedTunnelProvider.isEquivalent(to: $0) }) {
                    matchingTunnel.tunnelProvider = loadedTunnelProvider
                    matchingTunnel.refreshStatus()
                } else {
                    // Tunnel was added outside the app
                    if let configuration = loadedTunnelProvider.provider {
                        if configuration.migrateConfigurationIfNeeded(
                            with: loadedTunnelProvider.localizedDescription ?? "unknown"
                        ) {
                            loadedTunnelProvider.saveToPreferences { _ in }
                        }
                    }
                    let tunnel = TunnelContainer(tunnel: loadedTunnelProvider)
                    self.tunnels.append(tunnel)
                    self.tunnels.sort { TunnelsService.nameIsLess(lhs: $0.name, than: $1.name) }
                }
            }
        }
    }
}
