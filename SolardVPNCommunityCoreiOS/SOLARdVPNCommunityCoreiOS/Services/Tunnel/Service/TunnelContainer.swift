//
//  TunnelContainer.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit
import NetworkExtension

private struct Constants {
    let maxRecursionCount = 8
}

private let constants = Constants()

final public class TunnelContainer: NSObject {
    @objc dynamic var name: String
    @objc dynamic var status: TunnelStatus
    @objc dynamic var isActivateOnDemandEnabled: Bool

    var isAttemptingActivation = false {
        didSet {
            guard isAttemptingActivation else { return }
            activationTimer?.invalidate()
            let activationTimer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                log.debug(
                    """
                    Status update notification timeout for tunnel '\(self.name)'.
                    Tunnel status is now '\(self.tunnelProvider.connection.status.description)'.
                    """
                )
                switch self.tunnelProvider.connection.status {
                case .connected, .disconnected, .invalid:
                    self.activationTimer?.invalidate()
                    self.activationTimer = nil
                default:
                    break
                }
                self.refreshStatus()
            }
            self.activationTimer = activationTimer
            RunLoop.main.add(activationTimer, forMode: .common)
        }
    }

    private(set) var activationAttemptId: String?
    private var activationTimer: Timer?
    private var deactivationTimer: Timer?

    var tunnelProvider: NETunnelProviderManager

    var tunnelConfiguration: TunnelConfiguration? {
        return tunnelProvider.tunnelConfiguration
    }

    init(tunnel: NETunnelProviderManager) {
        name = tunnel.localizedDescription ?? "Unnamed"
        status = TunnelStatus(from: tunnel.connection.status)
        isActivateOnDemandEnabled = tunnel.isOnDemandEnabled
        tunnelProvider = tunnel
        super.init()
    }

    func refreshStatus() {
        if status == .restarting {
            return
        }
        status = TunnelStatus(from: tunnelProvider.connection.status)
        isActivateOnDemandEnabled = tunnelProvider.isOnDemandEnabled
    }

    func startActivation(
        recursionCount: UInt = 0,
        lastError: Error? = nil,
        statusDelegate: TunnelsServiceStatusDelegate?
    ) {
        guard recursionCount < constants.maxRecursionCount else {
            guard let lastError = lastError else {
                return
            }
            
            log.error("Failed after 8 attempts. Giving up with \(lastError.localizedDescription)")
            statusDelegate?.activationAttemptFailed(
                for: self,
                with: .retryLimitReached(lastSystemError: lastError)
            )
            return
        }

        log.debug("Entering (tunnel: \(name))")
        // Ensure that no other tunnel can attempt activation until this tunnel is done trying
        status = .connecting

        guard tunnelProvider.isEnabled else {
            log.debug("Tunnel is disabled. Re-enabling and saving")
            reActivateProvider(recursionCount: recursionCount, statusDelegate: statusDelegate)
            return
        }

        startTunnel(recursionCount: recursionCount, statusDelegate: statusDelegate)
    }

    func startDeactivation(statusDelegate: TunnelsServiceStatusDelegate?) {
        log.debug("startDeactivation: Tunnel: \(name)")
        tunnelProvider.providerSession?.stopTunnel()
        status = .disconnected
        statusDelegate?.deactivationSucceeded(for: self)
    }
}

private extension TunnelContainer {
    func reActivateProvider(
        recursionCount: UInt,
        statusDelegate: TunnelsServiceStatusDelegate?
    ) {
        tunnelProvider.isEnabled = true
        tunnelProvider.saveToPreferences { [weak self] error in
            guard let self = self else { return }
            guard let error = error else {
                log.debug("Tunnel saved after re-enabling, invoking startActivation")
                self.startActivation(
                    recursionCount: recursionCount + 1,
                    lastError: NEVPNError(NEVPNError.configurationUnknown),
                    statusDelegate: statusDelegate
                )
                return
            }
            log.error("Error saving tunnel after re-enabling: \(error)")
            statusDelegate?.activationAttemptFailed(for: self, with: .savingFailed(systemError: error))
        }
    }

    func startTunnel(
        recursionCount: UInt,
        statusDelegate: TunnelsServiceStatusDelegate?
    ) {
        do {
            log.debug("startActivation: Starting tunnel")
            isAttemptingActivation = true

            let activationAttemptId = UUID().uuidString
            self.activationAttemptId = activationAttemptId
            try tunnelProvider.providerSession?.startTunnel(options: ["activationAttemptId": activationAttemptId])
            log.debug("startActivation: Success")
            statusDelegate?.activationAttemptSucceeded(for: self)
        } catch let error {
            isAttemptingActivation = false

            guard let systemError = error as? NEVPNError else {
                log.error("Failed to activate tunnel: Error: \(error)")
                status = .disconnected
                statusDelegate?.activationAttemptFailed(for: self, with: .startingFailed(systemError: error))
                return
            }

            guard systemError.code == NEVPNError.configurationInvalid
                    || systemError.code == NEVPNError.configurationStale else {
                log.error("Failed to activate tunnel: VPN Error: \(error)")
                status = .disconnected
                statusDelegate?.activationAttemptFailed(for: self, with: .startingFailed(systemError: systemError))
                return
            }

            log.debug("Will reload tunnel and then try to start it.")
            tunnelProvider.loadFromPreferences { [weak self] error in
                guard let self = self else { return }
                guard let error = error else {
                    log.debug("startActivation: Tunnel reloaded, invoking startActivation")
                    self.startActivation(
                        recursionCount: recursionCount + 1,
                        lastError: systemError,
                        statusDelegate: statusDelegate
                    )
                    return
                }
                log.error("startActivation: Error reloading tunnel: \(error)")
                self.status = .disconnected
                statusDelegate?.activationAttemptFailed(for: self, with: .loadingFailed(systemError: error))
            }
        }
    }
}
