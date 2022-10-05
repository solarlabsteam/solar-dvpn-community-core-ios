//
//  ConnectionNodeModel.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation
import Combine
import SentinelWallet
import GRPC

// MARK: - Constants

private struct Constants {
    let timeout: TimeInterval = 15
    let denom = "udvpn"
}

private let constants = Constants()

// MARK: - ConnectionNodeModel

final class ConnectionNodeModel {
    typealias Delegate = ConnectionModelDelegate
    typealias Context = HasConnectionInfoStorage & HasSubscriptionsService & HasTunnelManager & HasWalletService
        & HasNodesService & HasSessionsService & HasWalletStorage
    private let context: Context
    
    private var cancellables = Set<AnyCancellable>()
    private(set) weak var delegate: Delegate?
    
    private var isTunnelActive: Bool {
        context.tunnelManager.isTunnelActive
    }
    
    init(context: Context, delegate: Delegate) {
        self.context = context
        self.delegate = delegate
    }
}

// MARK: - Connection functions

extension ConnectionNodeModel: ConnectionModelType {
    /// Should be called each time when we turn toggle to "on" state
    func connect(to node: String) -> Bool {
        if isTunnelActive {
            return false
        }
        loadSubscriptions(address: node)
        return true
    }
}

extension ConnectionNodeModel {
    private func loadSubscriptions(address: String) {
        delegate?.set(isLoading: true)
        
        context.subscriptionsService.loadActiveSubscriptions { [weak self] result in
            switch result {
            case let .success(subscriptions):
                guard let subscription = subscriptions.last(where: { $0.node == address }) else {
                    self?.delegate?.show(error: ConnectionModelError.noSubscription.body)
                    return
                }
                
                self?.detectConnectionAndHandle(connect: true, subscription: subscription)
                
            case let .failure(error):
                log.error(error)
                self?.delegate?.show(error: .init(code: 500, message: error.localizedDescription))
            }
        }
    }

    private func connect(to subscription: SentinelWallet.Subscription) {
        context.subscriptionsService.queryQuota(for: subscription.id) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.delegate?.show(error: .init(code: 500, message: error.localizedDescription))

            case .success(let quota):
                guard self.update(quota: quota, askForResubscription: true, subscription: subscription) else {
                    return
                }
                
                self.context.nodesService.getNode(by: subscription.node) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.delegate?.show(error: .init(code: 500, message: error.localizedDescription))
                    case .success(let node):
                        self?.createNewSession(subscription: subscription, nodeURL: node.remoteURL)
                    }
                }
            }
        }
    }
    
    private func update(quota: Quota, askForResubscription: Bool, subscription: SentinelWallet.Subscription) -> Bool {
        let initialBandwidth = quota.allocated
        let bandwidthConsumed = quota.consumed
        
        let bandwidthLeft = (Int64(initialBandwidth) ?? 0) - (Int64(bandwidthConsumed) ?? 0)
        
        return askForResubscription ? checkQuotaAndSubscription(hasQuota: bandwidthLeft != 0, subscription: subscription) : true
    }
    
    private func checkQuotaAndSubscription(hasQuota: Bool, subscription: SentinelWallet.Subscription) -> Bool {
          guard hasQuota, subscription.isActive else {
              delegate?.show(error: ConnectionModelError.noQuotaLeft.body)
              delegate?.set(isLoading: false)
              return false
          }
          
          return true
      }
    
    private func createNewSession(subscription: SentinelWallet.Subscription, nodeURL: String) {
        context.walletService.fetchBalance { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                log.debug("Failed to fetch a balance due to \(error). Try to start a session anyway.")
                self.startSession(on: subscription, nodeURL: nodeURL)
                
            case .success(let balances):
                guard balances
                    .contains(
                        where: { $0.denom == constants.denom && Int($0.amount) ?? 0 >= self.context.walletService.fee }
                    ) else {
                    self.delegate?.show(warning: WalletServiceError.notEnoughTokens.body)
                    self.delegate?.set(isLoading: false)
                    return
                }
                self.startSession(on: subscription, nodeURL: nodeURL)
            }
        }
    }

    private func startSession(on subscription: SentinelWallet.Subscription, nodeURL: String) {
        guard let nodeAddress = context.connectionInfoStorage.lastSelectedNode() else {
            return
        }
        
        context.sessionsService.startSession(on: subscription.id, node: nodeAddress) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.delegate?.show(error: .init(code: 500, message: error.localizedDescription))
            case .success(let id):
                self?.fetchConnectionData(remoteURLString: nodeURL, id: id)
                self?.context.connectionInfoStorage.set(lastSelectedNode: subscription.node)
            }
        }
    }
    
    private func detectConnectionAndHandle(
        considerStatus: Bool = true,
        connect: Bool,
        subscription: SentinelWallet.Subscription
    ) {
        detectConnection(node: subscription.node) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                log.error(error)
                if connect {
                    self.connect(to: subscription)
                }
                
            case let .success((isTunnelActive, isSessionActive)):
                switch (isTunnelActive, isSessionActive) {
                case (true, true):
                    self.delegate?.show(error: ConnectionModelError.tunnelIsAlreadyActive.body)
                case (false, true):
                    if let tunnel = self.context.tunnelManager.lastTunnel {
                        self.context.tunnelManager.startActivation(of: tunnel)
                    } else {
                        if connect {
                            self.connect(to: subscription)
                        } else {
                            self.delegate?.set(isLoading: false)
                        }
                    }
                case (true, false), (false, false):
                    self.connect(to: subscription)
                }
            }
        }
    }
    
    /// Checks if tunnel and session are active
    private func detectConnection(
        considerStatus: Bool = true,
        node: String,
        completion: @escaping (Result<(Bool, Bool), Error>) -> Void
    ) {
        var isTunnelActive: Bool

        if let tunnel = context.tunnelManager.lastTunnel {
            isTunnelActive = true
            
            if considerStatus {
                isTunnelActive = tunnel.status == .connected || tunnel.status == .connecting
            }
        } else {
            isTunnelActive = false
        }
        
        guard let sessionId = context.connectionInfoStorage.lastSessionId() else {
            completion(.success((isTunnelActive, false)))
            return
        }
        
        context.sessionsService.loadActiveSessions { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let session):
                guard session.contains(where: { $0.id == sessionId && $0.node == node }) else {
                    completion(.success((isTunnelActive, false)))
                    return
                }
                
                completion(.success((isTunnelActive, true)))
            }
        }
    }
}

// MARK: - Network and Wallet work

extension ConnectionNodeModel {
    private func fetchConnectionData(remoteURLString: String, id: UInt64) {
        var int = id.bigEndian
        let sessionIdData = Data(bytes: &int, count: 8)

        guard let signature = context.walletService.generateSignature(for: sessionIdData) else {
            delegate?.show(error: ConnectionModelError.signatureGenerationFailed.body)
            return
        }

        context.sessionsService.fetchConnectionData(
            remoteURLString: remoteURLString,
            id: id,
            accountAddress: context.walletStorage.walletAddress,
            signature: signature
        ) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                self.delegate?.show(error: .init(code: 500, message: error.localizedDescription))
            case let .success((data, wgKey)):
                self.context.connectionInfoStorage.set(sessionId: Int(id))
                self.context.tunnelManager.createNewProfile(
                    from: data,
                    with: wgKey
                )
            }
        }
    }
}
