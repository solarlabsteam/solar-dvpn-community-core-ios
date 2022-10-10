//
//  SessionsServiceType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 20.07.2022.
//

import Foundation
import SentinelWallet
import WireGuardKit

protocol SessionsServiceType {
    func loadActiveSessions(completion: @escaping (Result<[Session], Error>) -> Void)
    func stopActiveSessions(completion: @escaping (Result<Void, Error>) -> Void)
    func startSession(on subscriptionID: UInt64, node: String, completion: @escaping (Result<UInt64, Error>) -> Void)
    func fetchConnectionData(
        remoteURLString: String,
        id: UInt64,
        accountAddress: String,
        signature: String,
        completion: @escaping (Result<(Data, PrivateKey), Error>) -> Void
    )
}
