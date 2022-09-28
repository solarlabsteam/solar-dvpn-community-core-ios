//
//  PeersModel.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit

private struct Constants {
    let ipv4DefaultRouteString = "0.0.0.0/0"

    // Set of all non-private IPv4 IPs
    let ipv4DefaultRouteModRFC1918String = [
        "1.0.0.0/8", "2.0.0.0/8", "3.0.0.0/8", "4.0.0.0/6", "8.0.0.0/7", "11.0.0.0/8",
        "12.0.0.0/6", "16.0.0.0/4", "32.0.0.0/3", "64.0.0.0/2", "128.0.0.0/3",
        "160.0.0.0/5", "168.0.0.0/6", "172.0.0.0/12", "172.32.0.0/11", "172.64.0.0/10",
        "172.128.0.0/9", "173.0.0.0/8", "174.0.0.0/7", "176.0.0.0/4", "192.0.0.0/9",
        "192.128.0.0/11", "192.160.0.0/13", "192.169.0.0/16", "192.170.0.0/15",
        "192.172.0.0/14", "192.176.0.0/12", "192.192.0.0/10", "193.0.0.0/8",
        "194.0.0.0/7", "196.0.0.0/6", "200.0.0.0/5", "208.0.0.0/4"
    ]
}

private let constants = Constants()

enum PeerField: CaseIterable {
    case publicKey
    case preSharedKey
    case endpoint
    case persistentKeepAlive
    case allowedIPs
    case rxBytes
    case txBytes
    case lastHandshakeTime
    case excludePrivateIPs
    case deletePeer
}

final class PeersModel {
    var index: Int
    private var data = [PeerField: String]()

    var validatedConfiguration: PeerConfiguration?
    var publicKey: PublicKey? {
        if let validatedConfiguration = validatedConfiguration {
            return validatedConfiguration.publicKey
        }
        if let scratchPadPublicKey = data[.publicKey] {
            return PublicKey(base64Key: scratchPadPublicKey)
        }
        return nil
    }

    private(set) var shouldAllowExcludePrivateIPsControl = false
    private(set) var shouldStronglyRecommendDNS = false
    private(set) var excludePrivateIPsValue = false
    var numberOfPeers = 0

    init(index: Int) {
        self.index = index
    }

    subscript(field: PeerField) -> String {
        get {
            if data.isEmpty { fillData() }
            return data[field] ?? ""
        }
        set(stringValue) {
            if data.isEmpty { fillData() }
            validatedConfiguration = nil
            if stringValue.isEmpty {
                data.removeValue(forKey: field)
            } else {
                data[field] = stringValue
            }
            if field == .allowedIPs {
                updateExcludePrivateIPs()
            }
        }
    }

    func save() -> Result<PeerConfiguration, Error> {
        if let validatedConfiguration = validatedConfiguration { return .success(validatedConfiguration) }

        guard let publicKeyString = data[.publicKey] else {
            return .failure(TunnelSavingError.publicKeyRequired)
        }

        guard let publicKey = PublicKey(base64Key: publicKeyString) else {
            return .failure(TunnelSavingError.publicKeyInvalid)
        }

        var config = PeerConfiguration(publicKey: publicKey)
        
        if let preSharedKeyString = data[.preSharedKey] {
            guard let preSharedKey = PreSharedKey(base64Key: preSharedKeyString) else {
                return .failure(TunnelSavingError.preSharedKeyInvalid)
            }
            config.preSharedKey = preSharedKey
        }
        
        if let allowedIPsString = data[.allowedIPs] {
            let allowedIPs = allowedIPsString
                .splitToArray(trimmingCharacters: .whitespacesAndNewlines)
                .map { IPAddressRange(from: $0) }

            if allowedIPs.contains(nil) {
                return .failure(TunnelSavingError.allowedIPsInvalid)
            }

            config.allowedIPs = allowedIPs.compactMap { $0 }
        }

        if let endpointString = data[.endpoint] {
            guard let endpoint = Endpoint(from: endpointString) else {
                return .failure(TunnelSavingError.endpointInvalid)
            }
            config.endpoint = endpoint
        }

        if let persistentKeepAliveString = data[.persistentKeepAlive] {
            guard let persistentKeepAlive = UInt16(persistentKeepAliveString) else {
                return .failure(TunnelSavingError.persistentKeepAliveInvalid)
            }
            config.persistentKeepAlive = persistentKeepAlive
        }

        validatedConfiguration = config
        return .success(config)
    }

    func updateExcludePrivateIPs() {
        if data.isEmpty { fillData() }
        let allowedIPStrings = Set<String>(data[.allowedIPs].splitToArray(trimmingCharacters: .whitespacesAndNewlines))
        excludePrivateIPsFieldStates(isSinglePeer: numberOfPeers == 1, allowedIPs: allowedIPStrings)
        shouldStronglyRecommendDNS = allowedIPStrings.contains(constants.ipv4DefaultRouteString)
            || allowedIPStrings.isSuperset(of: constants.ipv4DefaultRouteModRFC1918String)
    }
}

private extension PeersModel {
    func excludePrivateIPsFieldStates(
        isSinglePeer: Bool,
        allowedIPs: Set<String>
    ) {
        guard isSinglePeer else {
            shouldAllowExcludePrivateIPsControl = false
            excludePrivateIPsValue = false
            return
        }

        let allowedIPStrings = Set<String>(allowedIPs)
        if allowedIPStrings.contains(constants.ipv4DefaultRouteString) {
            shouldAllowExcludePrivateIPsControl = true
            excludePrivateIPsValue = false
            return
        }

        if allowedIPStrings.isSuperset(of: constants.ipv4DefaultRouteModRFC1918String) {
            shouldAllowExcludePrivateIPsControl = true
            excludePrivateIPsValue = true
            return
        }

        shouldAllowExcludePrivateIPsControl = false
        excludePrivateIPsValue = false
    }

    func fillData() {
        guard let config = validatedConfiguration else { return }
        var data = [PeerField: String]()
        data[.publicKey] = config.publicKey.base64Key
        if let preSharedKey = config.preSharedKey?.base64Key {
            data[.preSharedKey] = preSharedKey
        }
        if !config.allowedIPs.isEmpty {
            data[.allowedIPs] = config.allowedIPs.map { $0.stringRepresentation }.joined(separator: ", ")
        }
        if let endpoint = config.endpoint {
            data[.endpoint] = endpoint.stringRepresentation
        }
        if let persistentKeepAlive = config.persistentKeepAlive {
            data[.persistentKeepAlive] = String(persistentKeepAlive)
        }
        if let rxBytes = config.rxBytes {
            data[.rxBytes] = "\(rxBytes) B"
        }
        if let txBytes = config.txBytes {
            data[.txBytes] = "\(txBytes) B"
        }
        if let lastHandshakeTime = config.lastHandshakeTime {
            data[.lastHandshakeTime] = "\(lastHandshakeTime) second ago"
        }
        self.data = data
        updateExcludePrivateIPs()
    }

}
