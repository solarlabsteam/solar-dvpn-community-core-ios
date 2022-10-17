//
//  TunnelModel.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit

final public class TunnelModel {
    static let keyLengthInBase64 = 44

    private(set) var interfaceModel: TunnelInterfaceModel
    private(set) var peersModel: [PeersModel]

    init(tunnelConfiguration: TunnelConfiguration?) {
        interfaceModel = TunnelInterfaceModel(
            configuration: tunnelConfiguration?.interface,
            name: tunnelConfiguration?.name
        )

        var peersData = [PeersModel]()
        if let tunnelConfiguration = tunnelConfiguration {
            peersData = tunnelConfiguration.peers.enumerated().map { index, configuration in
                let peerData = PeersModel(index: index)
                peerData.validatedConfiguration = configuration
                return peerData
            }
        }

        self.peersModel = peersData

        updatePeers()
    }

    func appendEmptyPeer() {
        let peer = PeersModel(index: peersModel.count)
        peersModel.append(peer)

        updatePeers()
    }

    func deletePeer(peer: PeersModel) {
        let removedPeer = peersModel.remove(at: peer.index)
        assert(removedPeer.index == peer.index)
        peersModel[peer.index ..< peersModel.count].forEach { peer in
            assert(peer.index > 0)
            peer.index -= 1
        }

        updatePeers()
    }

    func updateDNSServersIfRequired(oldServers: String, newServers: String) -> Bool {
        guard peersModel.count == 1, let firstPeer = peersModel.first else { return false }
        guard firstPeer.shouldAllowExcludePrivateIPsControl && firstPeer.excludePrivateIPsValue else { return false }

        let allowedIPStrings = firstPeer[.allowedIPs].splitToArray(trimmingCharacters: .whitespacesAndNewlines)
        let oldStrings = oldServers.splitToArray(trimmingCharacters: .whitespacesAndNewlines)
            .compactMap { IPAddressRange(from: $0) }
            .map { $0.stringRepresentation }

        let newStrings = newServers.splitToArray(trimmingCharacters: .whitespacesAndNewlines)
            .compactMap { IPAddressRange(from: $0) }
            .map { $0.stringRepresentation }

        let updatedAllowedIPStrings = allowedIPStrings.filter { !oldStrings.contains($0) } + newStrings
        firstPeer[.allowedIPs] = updatedAllowedIPStrings.joined(separator: ", ")

        return true
    }

    func save() -> Result<TunnelConfiguration, Error> {
        let interfaceSaveResult = interfaceModel.save()
        let peerSaveResults = peersModel.map { $0.save() }

        switch interfaceSaveResult {
        case .failure(let error):
            return .failure(error)

        case .success(let interfaceConfiguration):
            var peerConfigurations = [PeerConfiguration]()
            peerConfigurations.reserveCapacity(peerSaveResults.count)

            for peerSaveResult in peerSaveResults {
                switch peerSaveResult {
                case .failure(let error):
                    return .failure(error)
                case .success(let peerConfiguration):
                    peerConfigurations.append(peerConfiguration)
                }
            }

            let peerPublicKeysArray = peerConfigurations.map { $0.publicKey }
            let peerPublicKeysSet = Set<PublicKey>(peerPublicKeysArray)
            if peerPublicKeysArray.count != peerPublicKeysSet.count {
                return .failure(TunnelSavingError.publicKeyDuplicated)
            }

            let tunnelConfiguration = TunnelConfiguration(
                name: interfaceConfiguration.0,
                interface: interfaceConfiguration.1,
                peers: peerConfigurations
            )

            return .success(tunnelConfiguration)
        }
    }

    func asWireGuardConfig() -> String? {
        guard case .success(let tunnelConfiguration) = save() else { return nil }
        return tunnelConfiguration.asWireGuardConfig()
    }
}

private extension TunnelModel {
    func updatePeers() {
        let numberOfPeers = peersModel.count

        peersModel.forEach { peer in
            peer.numberOfPeers = numberOfPeers
            peer.updateExcludePrivateIPs()
        }
    }
}
