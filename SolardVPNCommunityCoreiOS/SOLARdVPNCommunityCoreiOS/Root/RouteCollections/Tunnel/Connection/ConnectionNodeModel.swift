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
    typealias Delegate = ConnectionModelDelegate & NodeModelDelegate
    typealias Context = HasConnectionInfoStorage & HasSubscriptionsService & HasTunnelManager & HasWalletService
        & HasNodesService & HasSessionsService & HasWalletStorage
    private let context: Context
    
    private var cancellables = Set<AnyCancellable>()
    private(set) weak var delegate: Delegate?
    
    private var subscription: SentinelWallet.Subscription?
    private var selectedNode: Node?
    
    private var isTunnelActive: Bool {
        context.tunnelManager.isTunnelActive
    }
    
    init(context: Context, delegate: Delegate) {
        self.context = context
        self.delegate = delegate
        
        loadData()
    }
}

// MARK: - Connection functions

extension ConnectionNodeModel: ConnectionModelType {
    func refreshNode() {
        checkNodeForUpdate()
    }
    
    /// Should be called each time when we turn toggle to "on" state
    func connect() {
        guard let subscription = subscription else {
            guard let selectedNode = selectedNode else {
                return
            }
            
            delegate?.openPlans(node: selectedNode, resubscribe: false)
            return
        }
        delegate?.set(isLoading: true)
        guard subscription.node == selectedNode?.address else {
            loadSubscriptions(reconnect: true, address: subscription.node)
            return
        }
        detectConnectionAndHandle(considerStatus: false, reconnect: true, subscription: subscription)
    }
}

// MARK: - Connection functions

extension ConnectionNodeModel {
    func loadData() {
        delegate?.set(isLoading: false)
        setSelectedOrDefaultNodeInfo()
    }
    
    /// Refreshes subscriptions. Should be called each time when the app leaves the background state.
    func refreshNodeState() {
        guard subscription != nil else { return }
        refreshSubscriptions()
    }
    
    /// Should be called each time when the view appears
    private func checkNodeForUpdate() {
        guard let address = context.connectionInfoStorage.lastSelectedNode() else {
            log.error("No last selected node")
            
            return
        }
        var time: Double = 0
        if isTunnelActive, let selectedNode = selectedNode?.address, selectedNode != address {
            context.tunnelManager.startDeactivationOfActiveTunnel()
            delegate?.set(isLoading: true)
            time = 2
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            self.updateLocation(address: address)
            self.refreshSubscriptions()
        }
    }
}

extension ConnectionNodeModel {
    // MARK: - Default last selected node
    private func setSelectedOrDefaultNodeInfo() {
        var address = context.connectionInfoStorage.lastSelectedNode() ?? defaultNodeAddress
        if address?.isEmpty == true {
            address = defaultNodeAddress
        }
        if let address = address {
            setInitialNodeInfo(address: address)
        }
    }
    
    private var defaultNodeAddress: String? {
        let trustedNode = context.nodesService.nodes.first(where: { $0.isTrusted })
        if let trustedNode = trustedNode {
            context.connectionInfoStorage.set(lastSelectedNode: trustedNode.address)
            return trustedNode.address
        }
        
        let randomNode = context.nodesService.nodes.randomElement()
        if let randomNode = randomNode {
            context.connectionInfoStorage.set(lastSelectedNode: randomNode.address)
        }
        
        return randomNode?.address
    }
    
    private func setInitialNodeInfo(address: String) {
        updateLocation(address: address)
        
        loadSubscriptions(address: address)
    }
    
    // MARK: - Subscriprion
    
    /// Returns false if no quota
    private func checkQuotaAndSubscription(hasQuota: Bool) -> Bool {
        guard hasQuota, subscription?.isActive ?? false else {
            guard let selectedNode = selectedNode else {
                return false
            }
            
            delegate?.openPlans(node: selectedNode, resubscribe: false)
            delegate?.set(isLoading: false)
            return false
        }
        
        return true
    }
    
    private func refreshSubscriptions() {
        delegate?.set(isLoading: false)
        
        guard let selectedAddress = context.connectionInfoStorage.lastSelectedNode() else {
            handleConnection(reconnect: false)
            return
        }
        loadSubscriptions(address: selectedAddress)
    }
    
    private func loadSubscriptions(reconnect: Bool = false, address: String) {
        context.subscriptionsService.loadActiveSubscriptions { [weak self] result in
            switch result {
            case let .success(subscriptions):
                guard let subscription = subscriptions.last(where: { $0.node == address }) else {
                    self?.handleConnection(reconnect: false)
                    return
                }
                
                self?.subscription = subscription
                self?.handleConnection(reconnect: false)
                
            case let .failure(error):
                log.error(error)
                self?.delegate?.show(error: error)
            }
        }
    }
    
    private func handleConnection(reconnect: Bool) {
        guard let subscription = subscription else {
            if context.tunnelManager.startDeactivationOfActiveTunnel() != true {
                delegate?.set(isLoading: false)
            }
            return
        }
        
        if reconnect {
            detectConnectionAndHandle(reconnect: reconnect, subscription: subscription)
        } else {
            update(subscriptionInfo: subscription, askForResubscription: false)
        }
    }
    
    private func update(
        subscriptionInfo: SentinelWallet.Subscription,
        askForResubscription: Bool = true
    ) {
        context.subscriptionsService.queryQuota(for: subscriptionInfo.id) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.delegate?.show(error: error)

            case .success(let quota):
                guard self.update(quota: quota, askForResubscription: askForResubscription) else {
                    return
                }
                self.delegate?.set(isLoading: false)
            }
        }

        updateLocation(address: subscriptionInfo.node)
    }

    private func connect(to subscription: SentinelWallet.Subscription) {
        context.subscriptionsService.queryQuota(for: subscription.id) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                self.delegate?.show(error: error)

            case .success(let quota):
                guard self.update(quota: quota, askForResubscription: true) else {
                    return
                }
                
                self.context.nodesService.getNode(by: subscription.node) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.delegate?.show(error: error)
                    case .success(let node):
                        self?.createNewSession(subscription: subscription, nodeURL: node.remoteURL)
                    }
                }
            }
        }
    }
    
    private func update(quota: Quota, askForResubscription: Bool) -> Bool {
        let initialBandwidth = quota.allocated
        let bandwidthConsumed = quota.consumed
        
        let bandwidthLeft = (Int64(initialBandwidth) ?? 0) - (Int64(bandwidthConsumed) ?? 0)
        
        return askForResubscription ? checkQuotaAndSubscription(hasQuota: bandwidthLeft != 0) : true
    }
    
    private func updateLocation(address: String) {
        context.nodesService.getNode(by: address) { [weak self] result in
            switch result {
            case let .failure(error):
                guard self?.subscription != nil else { return }
                log.error(error)
                self?.delegate?.show(error: ConnectionModelError.nodeIsOffline)
            case let .success(node):
                self?.selectedNode = node
            }
        }
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
                    self.delegate?.show(warning: WalletServiceError.notEnoughTokens)
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
                self?.delegate?.show(error: error)
            case .success(let id):
                self?.fetchConnectionData(remoteURLString: nodeURL, id: id)
            }
        }
    }
    
    private func detectConnectionAndHandle(
        considerStatus: Bool = true,
        reconnect: Bool,
        subscription: SentinelWallet.Subscription
    ) {
        detectConnection { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                log.error(error)
                if reconnect {
                    self.connect(to: subscription)
                }
                
            case let .success((isTunnelActive, isSessionActive)):
                switch (isTunnelActive, isSessionActive) {
                case (true, true):
                    self.update(subscriptionInfo: subscription)
                case (false, true):
                    if let tunnel = self.context.tunnelManager.lastTunnel {
                        self.context.tunnelManager.startActivation(of: tunnel)
                        self.update(subscriptionInfo: subscription)
                    } else {
                        if reconnect {
                            self.connect(to: subscription)
                        } else {
                            self.delegate?.set(isLoading: false)
                        }
                    }
                case (true, false), (false, false):
                    self.connect(to: subscription)
                    self.updateLocation(address: subscription.node)
                }
            }
        }
    }
    
    /// Checks if tunnel and session are active
    private func detectConnection(
        considerStatus: Bool = true,
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
        
        guard let sessionId = context.connectionInfoStorage.lastSessionId(),
              let node = context.connectionInfoStorage.lastSelectedNode() else {
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
            delegate?.show(error: ConnectionModelError.signatureGenerationFailed)
            return
        }
        
        guard let selectedNode = self.selectedNode else {
            delegate?.show(error: ConnectionModelError.noSelectedNode)
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
                switch error {
                case .noQuota:
                    self.delegate?.openPlans(node: selectedNode, resubscribe: true)
                    self.delegate?.set(isLoading: false)
                case .nodeMisconfigured:
                    self.delegate?.suggestUnsubscribe(from: selectedNode)
                    self.delegate?.set(isLoading: false)
                default:
                    self.delegate?.show(error: error)
                }
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
