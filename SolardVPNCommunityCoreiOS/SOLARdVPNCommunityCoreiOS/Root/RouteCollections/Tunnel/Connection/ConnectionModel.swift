//
//  ConnectionModel.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation
import Combine
import SentinelWallet
import GRPC

// MARK: - ConnectionModelEvent

enum ConnectionModelEvent {
    case error(SingleInnerError)
    case warning(SingleInnerError)
    case updateTunnelActivity(isActive: Bool)
}

// MARK: - ConnectionModel

final class ConnectionModel {
    typealias Delegate = ConnectionModelType
    typealias Context = ConnectionNodeModel.Context & HasWalletStorage
    private let context: Context
    
    private let eventSubject = PassthroughSubject<ConnectionModelEvent, Never>()
    var eventPublisher: AnyPublisher<ConnectionModelEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private var isTunnelActive: Bool {
        context.tunnelManager.isTunnelActive
    }

    private lazy var dvpnModel = ConnectionNodeModel(context: context, delegate: self)
    private weak var delegate: Delegate?
    
    init(context: Context) {
        self.context = context
        
        context.tunnelManager.delegate = self
        delegate = dvpnModel
        
        fetchWalletInfo()
    }
}

// MARK: - ConnectionModelDelegate

extension ConnectionModel: ConnectionModelDelegate {
    func set(isLoading: Bool) {
        if !isLoading { stopLoading() }
    }
}

// MARK: - Connection functions

extension ConnectionModel {
    /// Should be called each time when we turn toggle to "on" state
    func connect(to node: String) -> Bool {
        delegate?.connect(to: node) ?? false
    }
    
    /// Should be called each time when we turn toggle to "off" state
    func disconnect() -> Bool {
        context.tunnelManager.startDeactivationOfActiveTunnel()
    }
}

// MARK: - Events

extension ConnectionModel {
    internal func show(error: SingleInnerError) {
        log.error(error)
        stopLoading()
        
        eventSubject.send(.updateTunnelActivity(isActive: isTunnelActive))
        eventSubject.send(.error(error))
    }
    
    func show(warning: SingleInnerError) {
        eventSubject.send(.warning(warning))
    }
    
    private func stopLoading() {
        eventSubject.send(.updateTunnelActivity(isActive: isTunnelActive))
    }
}

// MARK: - Wallet

extension ConnectionModel {
    private func fetchWalletInfo() {
        context.walletService.fetchAuthorization { [weak self] error in
            if let error = error {
                if let statusError = error as? GRPC.GRPCStatus, statusError.code == .notFound {
                    return
                }
                self?.show(error: .init(code: 500, message: error.localizedDescription))
            }
        }

        context.walletService.fetchTendermintNodeInfo { [weak self] result in
            switch result {
            case .success(let info):
                log.debug(info)
            case .failure(let error):
                self?.show(error: .init(code: 500, message: error.localizedDescription))
            }
        }
    }
}

// MARK: - Account info

extension ConnectionModel {
    var address: String {
        context.walletStorage.walletAddress
    }
}

// MARK: - TunnelManagerDelegate

extension ConnectionModel: TunnelManagerDelegate {
    func handleTunnelUpdatingStatus() { }

    func handleError(_ error: Error) {
        show(error: .init(code: 500, message: error.localizedDescription))
    }

    func handleTunnelReconnection() { }
    
    func handleTunnelServiceCreation() { }
}

// MARK: - TunnelsServiceStatusDelegate

extension ConnectionModel: TunnelsServiceStatusDelegate {
    func activationAttemptFailed(for tunnel: TunnelContainer, with error: TunnelActivationError) {
        show(error: .init(code: 500, message: error.localizedDescription))
    }

    func activationAttemptSucceeded(for tunnel: TunnelContainer) {
        log.debug("\(tunnel.name) is succesfully attempted activation")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopLoading()
        }
    }

    func activationFailed(for tunnel: TunnelContainer, with error: TunnelActivationError) {
        show(error: .init(code: 500, message: error.localizedDescription))
    }

    func activationSucceeded(for tunnel: TunnelContainer) {
        log.debug("\(tunnel.name) is succesfully activated")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopLoading()
        }
    }

    func deactivationSucceeded(for tunnel: TunnelContainer) {
        log.debug("\(tunnel.name) is succesfully deactivated")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopLoading()
        }
    }
}
