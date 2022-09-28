//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import NetworkExtension
import WireGuardKit

enum PacketTunnelProviderError: String, Error {
    case savedProtocolConfigurationIsInvalid
    case dnsResolutionFailure
    case couldNotStartBackend
    case couldNotDetermineFileDescriptor
    case couldNotSetNetworkSettings
}

extension NETunnelProviderProtocol {
    convenience init?(tunnelConfiguration: TunnelConfiguration, previouslyFrom old: NEVPNProtocol? = nil) {
        self.init()
        guard let name = tunnelConfiguration.name, let bundleIdentifier = Bundle.main.bundleIdentifier else { return nil }
        providerBundleIdentifier = bundleIdentifier + ".network-extension"

        passwordReference = Keychain.makeReference(
            containing: tunnelConfiguration.asWireGuardConfig(),
            with: name,
            previouslyReferencedBy: old?.passwordReference
        )
        guard passwordReference != nil else { return nil }

        let endpoints = tunnelConfiguration.peers.compactMap { $0.endpoint }
        if endpoints.isEmpty {
            serverAddress = "Unspecified"
            return
        }
        if endpoints.count == 1 {
            serverAddress = endpoints[0].stringRepresentation
            return
        }
        serverAddress = "Multiple endpoints"
    }

    func asTunnelConfiguration(with name: String? = nil) -> TunnelConfiguration? {
        if let passwordReference = passwordReference, let config = Keychain.openReference(with: passwordReference) {
            return try? TunnelConfiguration(wireGuardConfig: config, with: name)
        }
        if let oldConfig = providerConfiguration?["WireGuardConfig"] as? String {
            return try? TunnelConfiguration(wireGuardConfig: oldConfig, with: name)
        }
        return nil
    }

    func destroyConfigurationReference() {
        guard let reference = passwordReference else { return }
        Keychain.deleteReference(with: reference)
    }

    func verifyConfigurationReference() -> Bool {
        guard let reference = passwordReference else { return false }
        return Keychain.verifyReference(called: reference)
    }

    @discardableResult
    func migrateConfigurationIfNeeded(with name: String) -> Bool {
        if let oldConfig = providerConfiguration?["WireGuardConfig"] as? String {
            providerConfiguration = nil
            guard passwordReference == nil else { return true }
            log.debug("Migrating tunnel configuration '\(name)'")
            passwordReference = Keychain.makeReference(containing: oldConfig, with: name)
            return true
        }
        return false
    }
}
