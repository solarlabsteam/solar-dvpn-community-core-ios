//
//  ContextBuilder.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 29.09.2022.
//

import Foundation
import SentinelWallet
import SOLARAPI

/// This class should configure all required services and inject them into a Context
final class ContextBuilder {
    func buildContext() -> CommonContext {
        let generalSettingsStorage = GeneralSettingsStorage()
        
        let nodesProvider = NodesProvider(configuration: .init(baseURL: ClientConstants.backendURL))
        let nodesService = NodesService(nodesProvider: nodesProvider)

        let securityService = SecurityService()
        let subscriptionsProvider = SubscriptionsProvider(configuration: ApplicationConfiguration.shared)
        let sessionProvider = NodeSessionProvider()
        let walletService = buildWalletService(storage: generalSettingsStorage, securityService: securityService)
        
        let sessionsService = SessionsService(
            sessionProvider: sessionProvider,
            subscriptionsProvider: subscriptionsProvider,
            walletService: walletService
        )
        let subscriptionsService = SubscriptionsService(
            subscriptionsProvider: subscriptionsProvider,
            walletService: walletService
        )
        
        let tunnelManager = TunnelManager(storage: generalSettingsStorage)
        
        return CommonContext(
            generalSettingStorage: generalSettingsStorage,
            commonStorage: UserDefaultsStorageStrategy(),
            safeStorage: KeychainStorageStrategy(serviceKey: "CommunityCoreSafeStorage"),
            nodesProvider: nodesProvider,
            securityService: securityService,
            walletService: walletService,
            nodesService: nodesService,
            subscriptionsService: subscriptionsService,
            sessionsService: sessionsService,
            tunnelManager: tunnelManager
        )
    }
    
    func buildWalletService(
        storage: StoresWallet,
        securityService: SecurityService
    ) -> WalletService {
        let walletAddress = storage.walletAddress
        let grpc = ApplicationConfiguration.shared
        guard !walletAddress.isEmpty else {
            let mnemonic = securityService.generateMnemonics().components(separatedBy: " ")
            switch securityService.restore(from: mnemonic) {
            case .failure(let error):
                fatalError("failed to generate wallet due to \(error), terminate")
            case .success(let address):
                saveMnemonicsIfNeeded(for: address, mnemonics: mnemonic, securityService: securityService)
                storage.set(wallet: address)
                return .init(
                    for: address,
                    configuration: grpc,
                    securityService: securityService
                )
            }
        }
        return WalletService(
            for: walletAddress,
            configuration: grpc,
            securityService: securityService
        )
    }
    
    private func saveMnemonicsIfNeeded(
        for account: String,
        mnemonics: [String],
        securityService: SecurityService
    ) {
        guard !securityService.mnemonicsExists(for: account) else { return }
        if !securityService.save(mnemonics: mnemonics, for: account) {
            log.error("Failed to save mnemonics info")
        }
    }
}
