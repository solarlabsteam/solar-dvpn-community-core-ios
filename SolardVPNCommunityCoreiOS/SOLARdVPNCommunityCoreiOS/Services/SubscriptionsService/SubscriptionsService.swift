//
//  SubscriptionsService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 20.07.2022.
//

import Foundation
import Combine
import SentinelWallet

enum SubscriptionsServiceError: String, LocalizedError {
    case missingMnemonic = "missing_mnemonic"
    case paymentFailed = "payment_failed"
    case faliToCancelSubscription = "fali_to_cancel_subscription"
    case activeSession = "active_session"
    
    var errorDescription: String? {
        self.rawValue
    }
}

final class SubscriptionsService {
    private let walletService: WalletService
    private let subscriptionsProvider: SubscriptionsProviderType
    
    init(
        subscriptionsProvider: SubscriptionsProviderType,
        walletService: WalletService
    ) {
        self.subscriptionsProvider = subscriptionsProvider
        self.walletService = walletService
    }
}

// MARK: - SubscriptionsServiceType

extension SubscriptionsService: SubscriptionsServiceType {
    func loadActiveSubscriptions(completion: @escaping (Result<[SentinelWallet.Subscription], Error>) -> Void) {
        subscriptionsProvider.querySubscriptions(
            for: walletService.currentWalletAddress,
            with: .active
        ) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let subscriptions):
                completion(.success(subscriptions))
            }
        }
    }
    
    func checkBalanceAndSubscribe(
        to node: String,
        deposit: CoinToken,
        completion:  @escaping (Result<Bool, Error>) -> Void
    ) {
        walletService.fetchBalance { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let balances):
                let balance = balances
                    .first(where: { $0.denom == deposit.denom })

                guard let balance = balance,
                      Int(balance.amount) ?? 0 >= (Int(deposit.amount) ?? 0 + self.walletService.fee) else {
                    completion(.success(false))
                    return
                }

                self.subscribe(to: node, with: deposit, completion: completion)
            }
        }
    }
    
    func cancel(subscriptions: [UInt64], with nodeAddress: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let sender = walletService.createTransactionSender() else {
            completion(.failure(SubscriptionsServiceError.missingMnemonic))
            return
        }
        
        subscriptionsProvider.cancel(subscriptions: subscriptions, sender: sender, node: nodeAddress) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(result):
                switch result.isSuccess {
                case true:
                    completion(.success(()))
                case false:
                    // Subscription can not be cancelled if active sessions exist
                    if result.rawLog.contains("can not cancel") {
                        completion(.failure(SubscriptionsServiceError.activeSession))
                        return
                    }
                    completion(.failure(SubscriptionsServiceError.faliToCancelSubscription))
                }
            }
        }
    }
    
    func queryQuota(for subscription: UInt64, completion: @escaping (Result<Quota, Error>) -> Void) {
        subscriptionsProvider.queryQuota(
            address: walletService.currentWalletAddress,
            subscriptionId: subscription
        ) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(quota):
                completion(.success(quota))
            }
        }
    }
}

// MARK: - Private methods

extension SubscriptionsService {
    private func subscribe(to node: String, with deposit: CoinToken, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let sender = walletService.createTransactionSender() else {
            completion(.failure(SubscriptionsServiceError.missingMnemonic))
            return
        }
        
        subscriptionsProvider.subscribe(sender: sender, node: node, deposit: deposit) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let response):
                guard response.isSuccess else {
                    completion(.failure(SubscriptionsServiceError.paymentFailed))
                    return
                }

                completion(.success(true))
            }
        }
    }
}
