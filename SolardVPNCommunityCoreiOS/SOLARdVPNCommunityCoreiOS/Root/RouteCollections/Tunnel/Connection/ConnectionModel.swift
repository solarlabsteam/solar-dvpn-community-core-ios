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
    case error(Error)
    case warning(Error)
    case info(String)
    
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

// MARK: - NodeModelDelegate

extension ConnectionModel: NodeModelDelegate {
    func suggestUnsubscribe(from node: Node) {
        eventSubject.send(.error(SessionsServiceError.nodeMisconfigured))
    }
    
    func openPlans(node: Node, resubscribe: Bool) {
        eventSubject.send(.error(resubscribe ? ConnectionModelError.noQuotaLeft : .noSubscription))
    }
}

// MARK: - Connection functions

extension ConnectionModel {
    func setInitData() {
        updateConnectionType(forceUpdate: true, disconnect: false)
    }
    
    func refresh() {
        updateConnectionType()
    }
    
    /// Should be called each time when we turn toggle to "on" state
    func connect() {
        delegate?.connect()
    }
    
    /// Should be called each time when we turn toggle to "off" state
    func disconnect() {
        guard let tunnel = context.tunnelManager.lastTunnel, tunnel.status != .disconnected else {
            stopLoading()
            return
        }
        
        context.tunnelManager.startDeactivation(of: tunnel)
    }
    
    func cancelSubscriptions(for nodeAddress: String) {
        context.subscriptionsService.loadActiveSubscriptions { [weak self] result in
            switch result {
            case let .success(subscriptions):
                let subscriptionsToCancel = subscriptions.filter { $0.node == nodeAddress }.map { $0.id }
                
                self?.context.subscriptionsService.cancel(
                    subscriptions: subscriptionsToCancel,
                    with: nodeAddress
                ) { [weak self] result in
                    switch result {
                    case let .failure(error):
                        self?.show(error: error)
                    case .success:
                        self?.handleCancellation(address: nodeAddress)
                    }
                }
            case let .failure(error):
                self?.show(error: error)
            }
        }
    }
}

// MARK: - Events

extension ConnectionModel {
    internal func show(error: Error) {
        log.error(error)
        stopLoading()
        
        eventSubject.send(.updateTunnelActivity(isActive: isTunnelActive))
        eventSubject.send(.error(error))
    }
    
    func show(warning: Error) {
        eventSubject.send(.warning(warning))
    }
    
    private func stopLoading() {
        eventSubject.send(.updateTunnelActivity(isActive: isTunnelActive))
    }
    
    private func handleCancellation(address: String) {
        eventSubject.send(.info(TunnelRouteEvent.subscriptionCanceled.rawValue))
        
        stopLoading()
        delegate?.refreshNode()
    }
}

// MARK: - Connection type

extension ConnectionModel {
    func updateConnectionType(forceUpdate: Bool = false, disconnect: Bool = true) {
        guard forceUpdate else {
            delegate?.refreshNode()
            return
        }

        if disconnect {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.disconnect()
            }
        }
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
                self?.show(error: error)
            }
        }

        context.walletService.fetchTendermintNodeInfo { [weak self] result in
            switch result {
            case .success(let info):
                log.debug(info)
            case .failure(let error):
                self?.show(error: error)
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
        show(error: error)
    }

    func handleTunnelReconnection() { }
    
    func handleTunnelServiceCreation() { }
}

// MARK: - TunnelsServiceStatusDelegate

extension ConnectionModel: TunnelsServiceStatusDelegate {
    func activationAttemptFailed(for tunnel: TunnelContainer, with error: TunnelActivationError) {
        show(error: error)
    }

    func activationAttemptSucceeded(for tunnel: TunnelContainer) {
        log.debug("\(tunnel.name) is succesfully attempted activation")

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.stopLoading()
        }
    }

    func activationFailed(for tunnel: TunnelContainer, with error: TunnelActivationError) {
        show(error: error)
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
