//
//  NETunnelProviderManager+Ext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit
import NetworkExtension

extension NETunnelProviderManager {
    private static var cachedKey: UInt8 = 0

    var providerSession: NETunnelProviderSession? {
        connection as? NETunnelProviderSession
    }

    var provider: NETunnelProviderProtocol? {
        protocolConfiguration as? NETunnelProviderProtocol
    }

    var tunnelConfiguration: TunnelConfiguration? {
        if let cached = objc_getAssociatedObject(self, &NETunnelProviderManager.cachedKey) as? TunnelConfiguration {
            return cached
        }

        guard let provider = protocolConfiguration as? NETunnelProviderProtocol,
              let config = provider.asTunnelConfiguration(with: localizedDescription) else {
            return nil
        }

        objc_setAssociatedObject(
            self, &NETunnelProviderManager.cachedKey,
            config,
            objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        return config
    }

    func set(tunnelConfiguration: TunnelConfiguration) {
        protocolConfiguration = NETunnelProviderProtocol(
            tunnelConfiguration: tunnelConfiguration,
            previouslyFrom: protocolConfiguration
        )
        localizedDescription = tunnelConfiguration.name
        objc_setAssociatedObject(
            self, &NETunnelProviderManager.cachedKey,
            tunnelConfiguration, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    func isEquivalent(to tunnel: TunnelContainer) -> Bool {
        localizedDescription == tunnel.name && tunnelConfiguration == tunnel.tunnelConfiguration
    }
}
