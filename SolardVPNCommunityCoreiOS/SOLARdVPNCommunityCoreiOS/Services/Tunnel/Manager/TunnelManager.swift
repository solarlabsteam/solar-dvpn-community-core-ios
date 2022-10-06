//
//  TunnelManager.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import WireGuardKit

private struct Constants {
    let persistentKeepAlive = "25"
    let allowedIPs = "0.0.0.0/0"
    let tunnelName = "dVPN tunnel"
}

private let constants = Constants()

protocol TunnelManagerDelegate: AnyObject {
    func handleTunnelUpdatingStatus()
    func handleError(_ error: Error)
    func handleTunnelReconnection()
    func handleTunnelServiceCreation()
}

final public class TunnelManager {
    private let storage: StoresDNSServers
    
    private var tunnelModel: TunnelModel
    private var tunnelsService: TunnelsService?
    
    weak var delegate: TunnelManagerTypeDelegate? {
        didSet {
            tunnelsService?.statusDelegate = delegate
        }
    }

    init(
        storage: StoresDNSServers,
        tunnelModel: TunnelModel = TunnelModel(tunnelConfiguration: nil)
    ) {
        self.storage = storage
        self.tunnelModel = tunnelModel
        
        createTunnelService()
    }
}

// MARK: TunnelManagerType

extension TunnelManager: TunnelManagerType {
    public var lastTunnel: TunnelContainer? {
        tunnelsService?.tunnels.last
    }
    
    public var isTunnelActive: Bool {
        tunnelsService?.tunnels.last?.status == .connected
    }

    public func prepareTunnelModel() {
        tunnelModel.interfaceModel[.name] = constants.tunnelName
        if tunnelModel.peersModel.isEmpty {
            tunnelModel.appendEmptyPeer()
        }
        tunnelModel.peersModel[0][.allowedIPs] = constants.allowedIPs
        tunnelModel.peersModel[0][.persistentKeepAlive] = constants.persistentKeepAlive
    }

    @discardableResult
    public func startDeactivationOfActiveTunnel() -> Bool {
        tunnelsService?.startDeactivationOfActiveTunnel() ?? false
    }

    public func startActivation(of tunnel: TunnelContainer) {
        tunnelsService?.set(onDemandEnabled: true, for: tunnel) { [weak self] _ in
            self?.tunnelsService?.startActivation(of: tunnel)
        }
    }

    public func startDeactivation(of tunnel: TunnelContainer) {
        tunnelsService?.set(onDemandEnabled: false, for: tunnel) { [weak self] _ in
            self?.tunnelsService?.startDeactivation(of: tunnel)
        }
    }

    public func createNewProfile(
        from data: Data,
        with privateKey: PrivateKey
    ) {
        delegate?.handleTunnelUpdatingStatus()

        tunnelModel.interfaceModel[.privateKey] = privateKey.base64Key
        tunnelModel.interfaceModel[.publicKey] = privateKey.publicKey.base64Key

        tunnelModel.interfaceModel[.dns] = storage.selectedDNS.address

        tunnelModel.interfaceModel[.addresses] = "\(data[0]).\(data[1]).\(data[2]).\(data[3])/32"
        let port = data.bytes[24...25]
            .withUnsafeBytes { $0.load(as: UInt16.self) }
            .bigEndian
            .description

        tunnelModel.interfaceModel[.listenPort] = port

        let host = "\(data[20]).\(data[21]).\(data[22]).\(data[23])"
        tunnelModel.peersModel[0][.endpoint] = "\(host):\(port)"

        let peerPubKeyBytes = data.bytes[26...57]
        let peerPubKeyData = Data(peerPubKeyBytes)
        let peerPubKey = PublicKey(rawValue: peerPubKeyData)
        tunnelModel.peersModel[0][.publicKey] = peerPubKey?.base64Key ?? ""

        upsertTunnel()
    }

    public func update(with server: String) {
        guard isTunnelActive else {
            return
        }
        
        tunnelModel.interfaceModel[.dns] = server
        upsertTunnel(startActivation: false)
    }
    
    public func resetVPNConfiguration(completion: @escaping (TunnelsServiceError?) -> Void) {
        guard let tunnelsService = tunnelsService else { return }
        
        tunnelsService.removeMultiple(tunnels: tunnelsService.tunnels, completion: completion)
    }
}

// MARK: Private functions

extension TunnelManager {
    private func createTunnelService() {
        TunnelsService.create { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.delegate?.handleError(error)

            case .success(let tunnelsService):
                self.tunnelsService = tunnelsService
                tunnelsService.refreshStatuses()
                tunnelsService.statusDelegate = self.delegate

                if let tunnel = tunnelsService.tunnels.last {
                    self.tunnelModel = .init(tunnelConfiguration: tunnel.tunnelConfiguration)
                }

                self.prepareTunnelModel()
            }
            
            self.delegate?.handleTunnelServiceCreation()
        }
    }
    
    private func upsertTunnel(startActivation: Bool = true) {
        delegate?.handleTunnelUpdatingStatus()

        switch tunnelModel.save() {
        case .failure(let error):
            delegate?.handleError(error)

        case .success(let tunnelConfiguration):
            guard let tunnel = tunnelsService?.tunnels.last else {
                addTunnel(
                    tunnelConfiguration: tunnelConfiguration,
                    startActivation: startActivation
                )
                return
            }
            modifyTunnel(
                tunnel: tunnel,
                with: tunnelConfiguration,
                startActivation: startActivation
            )
        }
    }

    private func addTunnel(
        tunnelConfiguration: TunnelConfiguration,
        startActivation: Bool
    ) {
        tunnelsService?.add(tunnelConfiguration: tunnelConfiguration) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                self.delegate?.handleError(error)
                
            case .success(let tunnel):
                guard startActivation else {
                    return
                }
                
                self.tunnelsService?.startActivation(of: tunnel)
            }
        }
    }

    private func modifyTunnel(
        tunnel: TunnelContainer,
        with tunnelConfiguration: TunnelConfiguration,
        startActivation: Bool
    ) {
        tunnelsService?.modify(
            tunnel: tunnel, tunnelConfiguration: tunnelConfiguration
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.delegate?.handleError(error)

            case .success(let tunnel):
                guard startActivation && tunnel.status != .restarting else {
                    self.delegate?.handleTunnelReconnection()
                    return
                }
                self.tunnelsService?.startActivation(of: tunnel)
            }
        }
    }
}
