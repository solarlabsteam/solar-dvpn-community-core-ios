//
//  NEVPNManager+Ext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import NetworkExtension

extension NEVPNManager {
    var tunnelBundleIdentifier: String? {
        guard let proto = protocolConfiguration as? NETunnelProviderProtocol else {
            return nil
        }
        return proto.providerBundleIdentifier
    }
    
    func isTunnel(withIdentifier bundleIdentifier: String) -> Bool {
        return tunnelBundleIdentifier == bundleIdentifier
    }
}
