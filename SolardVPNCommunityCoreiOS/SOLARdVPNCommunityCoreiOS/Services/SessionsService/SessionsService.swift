//
//  SessionsService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 20.07.2022.
//

import Foundation
import SentinelWallet
import SOLARAPI
import WireGuardKit
import Vapor

final class SessionsService {
    private let walletService: WalletService
    private let sessionProvider: NodeSessionProviderType
    private let subscriptionsProvider: SubscriptionsProviderType
    
    init(
        sessionProvider: NodeSessionProviderType,
        subscriptionsProvider: SubscriptionsProviderType,
        walletService: WalletService
    ) {
        self.sessionProvider = sessionProvider
        self.subscriptionsProvider = subscriptionsProvider
        self.walletService = walletService
    }
}

// MARK: - SubscriptionsServiceType

extension SessionsService: SessionsServiceType {
    func loadActiveSessions(completion: @escaping (Result<[SentinelWallet.Session], Error>) -> Void) {
        subscriptionsProvider.queryActiveSessions(for: walletService.currentWalletAddress, completion: completion)
    }
    
    func stopActiveSessions(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sender = walletService.createTransactionSender() else {
            completion(.failure(SubscriptionsServiceError.missingMnemonic))
            return
        }
        
        subscriptionsProvider.stopActiveSessions(sender: sender, completion: completion)
    }
    
    func startSession(on subscriptionID: UInt64, node: String, completion: @escaping (Result<UInt64, Error>) -> Void) {
        guard let sender = walletService.createTransactionSender() else {
            completion(.failure(SubscriptionsServiceError.missingMnemonic))
            return
        }
        
        subscriptionsProvider.startNewSession(on: subscriptionID, sender: sender, node: node, completion: completion)
    }
    
    func fetchConnectionData(
        remoteURLString: String,
        id: UInt64,
        accountAddress: String,
        signature: String,
        completion: @escaping (Result<(Data, PrivateKey), Error>) -> Void
    ) {
        guard var components = URLComponents(string: remoteURLString) else {
            completion(.failure(SessionsServiceError.invalidURL))
            return
        }
        components.scheme = "http"
        
        guard let urlString = components.string, let remoteURL = URL(string: urlString) else {
            completion(.failure(SessionsServiceError.invalidURL))
            return
        }
        let wgKey = PrivateKey()
        
        sessionProvider.createClient(
            remoteURL: remoteURL,
            address: accountAddress,
            id: "\(id)",
            request: .init(key: wgKey.publicKey.base64Key, signature: signature)) { result in
                switch result {
                case .success(let infoResult):
                    guard infoResult.success, let stringData = infoResult.result else {
                        completion(.failure(SessionsServiceError.connectionParsingFailed))
                        return
                    }
                    guard let data = Data(base64Encoded: stringData), data.bytes.count == 58 else {
                        completion(.failure(SessionsServiceError.connectionParsingFailed))
                        return
                    }
                    
                    completion(.success((data, wgKey)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
