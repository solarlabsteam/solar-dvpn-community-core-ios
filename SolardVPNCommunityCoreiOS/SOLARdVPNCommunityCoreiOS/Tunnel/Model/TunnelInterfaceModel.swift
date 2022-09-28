//
//  TunnelInterfaceModel.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit
import NetworkExtension

enum TunnelInterfaceField: CaseIterable {
    case name
    case privateKey
    case publicKey
    case generateKeyPair
    case addresses
    case listenPort
    case mtu
    case dns
    case status
    case toggleStatus
}

final class TunnelInterfaceModel {
    private var data = [TunnelInterfaceField: String]()

    private var validatedConfiguration: InterfaceConfiguration?
    private var validatedName: String?

    subscript(field: TunnelInterfaceField) -> String {
        get {
            if data.isEmpty {
                fillData()
            }
            return data[field] ?? ""
        }
        set(stringValue) {
            if data.isEmpty {
                fillData()
            }
            validatedConfiguration = nil
            validatedName = nil
            if stringValue.isEmpty {
                data.removeValue(forKey: field)
            } else {
                data[field] = stringValue
            }
            if field == .privateKey {
                if stringValue.count == TunnelModel.keyLengthInBase64,
                   let privateKey = PrivateKey(base64Key: stringValue) {
                    data[.publicKey] = privateKey.publicKey.base64Key
                } else {
                    data.removeValue(forKey: .publicKey)
                }
            }
        }
    }

    init(configuration: InterfaceConfiguration? = nil, name: String? = nil) {
        self.validatedConfiguration = configuration
        self.validatedName = name
    }

    func save() -> Result<(String, InterfaceConfiguration), Error> {
        if let config = validatedConfiguration, let name = validatedName { return .success((name, config)) }

        guard let name = data[.name]?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return .failure(TunnelSavingError.nameRequired)
        }
        guard let privateKeyString = data[.privateKey] else {
            return .failure(TunnelSavingError.privateKeyRequired)
        }
        guard let privateKey = PrivateKey(base64Key: privateKeyString) else {
            return .failure(TunnelSavingError.privateKeyInvalid)
        }

        var config = InterfaceConfiguration(privateKey: privateKey)

        if let addressesString = data[.addresses] {
            let addresses = addressesString
                .splitToArray(trimmingCharacters: .whitespacesAndNewlines)
                .map { IPAddressRange(from: $0) }

            if addresses.contains(nil) {
                return .failure(TunnelSavingError.addressInvalid)
            }

            config.addresses = addresses.compactMap { $0 }
        }

        if let listenPortString = data[.listenPort] {
            guard let listenPort = UInt16(listenPortString) else {
                return .failure(TunnelSavingError.listenPortInvalid)
            }
            config.listenPort = listenPort

        }

        if let mtuString = data[.mtu] {
            guard let mtu = UInt16(mtuString), mtu >= 576 else {
                return .failure(TunnelSavingError.MTUInvalid)
            }
            config.mtu = mtu
        }

        if let dnsString = data[.dns] {
            var dnsServers = [DNSServer]()
            var dnsSearch = [String]()

            for dnsServerString in dnsString.splitToArray(trimmingCharacters: .whitespacesAndNewlines) {
                if let dnsServer = DNSServer(from: dnsServerString) {
                    dnsServers.append(dnsServer)
                } else {
                    dnsSearch.append(dnsServerString)
                }
            }

            config.dns = dnsServers
            config.dnsSearch = dnsSearch
        }

        validatedConfiguration = config
        validatedName = name

        return .success((name, config))
    }
}

private extension TunnelInterfaceModel {
    func fillData() {
        guard let config = validatedConfiguration, let name = validatedName else { return }

        var data = [TunnelInterfaceField: String]()
        data[.name] = name
        data[.privateKey] = config.privateKey.base64Key
        data[.publicKey] = config.privateKey.publicKey.base64Key

        if !config.addresses.isEmpty {
            data[.addresses] = config.addresses.map { $0.stringRepresentation }.joined(separator: ", ")
        }
        if let listenPort = config.listenPort {
            data[.listenPort] = String(listenPort)
        }
        if let mtu = config.mtu {
            data[.mtu] = String(mtu)
        }

        if !config.dns.isEmpty || !config.dnsSearch.isEmpty {
            var dns = config.dns.map { $0.stringRepresentation }
            dns.append(contentsOf: config.dnsSearch)
            data[.dns] = dns.joined(separator: ", ")
        }

        self.data = data
    }
}
