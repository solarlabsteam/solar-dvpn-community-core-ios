//
//  CommonContext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 29.09.2022.
//

import Foundation
import SentinelWallet
import SOLARAPI

protocol NoContext {}

final class CommonContext {
    typealias Storage = StoresConnectInfo & StoresWallet & StoresDNSServers
    let storage: Storage
    
    // Providers
    let nodesProvider: SOLARAPI.NodesProviderType

    // Services
    let securityService: SecurityService
    let nodesService: NodesServiceType
    
    let walletService: WalletService
    let subscriptionsService: SubscriptionsServiceType
    let sessionsService: SessionsServiceType
    
    let tunnelManager: TunnelManagerType
    
    init(
        storage: Storage,
        nodesProvider: SOLARAPI.NodesProviderType,
        securityService: SecurityService,
        walletService: WalletService,
        nodesService: NodesServiceType,
        subscriptionsService: SubscriptionsServiceType,
        sessionsService: SessionsServiceType,
        tunnelManager: TunnelManagerType
    ) {
        self.storage = storage
        self.nodesProvider = nodesProvider
        self.securityService = securityService
        self.walletService = walletService
        self.nodesService = nodesService
        self.subscriptionsService = subscriptionsService
        self.sessionsService = sessionsService
        self.tunnelManager = tunnelManager
    }
}

protocol HasWalletService {
    var walletService: WalletService { get }
    
    func updateWalletContext()
    func resetWalletContext()
}

extension CommonContext: HasWalletService {
    func updateWalletContext() {
        let walletAddress = storage.walletAddress
        guard !walletAddress.isEmpty else { return }
        walletService.manage(address: walletAddress)
    }
    
    func resetWalletContext() {
        let mnemonics = securityService.generateMnemonics().components(separatedBy: " ")
        switch securityService.restore(from: mnemonics) {
        case .failure(let error):
            fatalError("failed to generate wallet due to \(error), terminate")
        case .success(let address):
            saveMnemonicsIfNeeded(for: address, mnemonics: mnemonics)
            storage.set(wallet: address)
            updateWalletContext()
        }
    }
    
    private func saveMnemonicsIfNeeded(for account: String, mnemonics: [String]) {
        guard !securityService.mnemonicsExists(for: account) else { return }
        if !self.securityService.save(mnemonics: mnemonics, for: account) {
            log.error("Failed to save mnemonics info")
        }
    }
}

protocol HasSubscriptionsService { var subscriptionsService: SubscriptionsServiceType { get } }
extension CommonContext: HasSubscriptionsService {}

protocol HasNodesProvider { var nodesProvider: SOLARAPI.NodesProviderType { get } }
extension CommonContext: HasNodesProvider {}

protocol HasNodesService { var nodesService: NodesServiceType { get } }
extension CommonContext: HasNodesService {}

protocol HasTunnelManager { var tunnelManager: TunnelManagerType { get } }
extension CommonContext: HasTunnelManager {}

protocol HasSessionsService { var sessionsService: SessionsServiceType { get } }
extension CommonContext: HasSessionsService {}

protocol HasSecurityService { var securityService: SecurityService { get } }
extension CommonContext: HasSecurityService {}

// MARK: - Storages

protocol HasConnectionInfoStorage { var connectionInfoStorage: StoresConnectInfo { get } }
extension CommonContext: HasConnectionInfoStorage {
    var connectionInfoStorage: StoresConnectInfo {
        storage as StoresConnectInfo
    }
}

protocol HasWalletStorage { var walletStorage: StoresWallet { get } }
extension CommonContext: HasWalletStorage {
    var walletStorage: StoresWallet {
        storage as StoresWallet
    }
}
