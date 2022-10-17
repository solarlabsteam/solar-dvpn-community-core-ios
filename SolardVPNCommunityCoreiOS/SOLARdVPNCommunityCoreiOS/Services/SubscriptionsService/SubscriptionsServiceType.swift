//
//  SubscriptionsServiceType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 20.07.2022.
//

import Foundation
import SentinelWallet

protocol SubscriptionsServiceType {
    func loadActiveSubscriptions(completion: @escaping (Result<[SentinelWallet.Subscription], Error>) -> Void)
    func checkBalanceAndSubscribe(
        to node: String,
        deposit: CoinToken,
        completion: @escaping (Result<Bool, Error>) -> Void
    )
    func cancel(subscriptions: [UInt64], with nodeAddress: String, completion: @escaping (Result<Void, Error>) -> Void)
    func queryQuota(for subscription: UInt64, completion: @escaping (Result<Quota, Error>) -> Void)
}
