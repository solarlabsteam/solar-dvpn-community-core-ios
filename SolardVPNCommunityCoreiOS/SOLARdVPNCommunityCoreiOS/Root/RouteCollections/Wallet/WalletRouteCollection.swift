//
//  WalletRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 04.10.2022.
//

import Foundation
import Vapor

struct WalletRouteCollection: RouteCollection {
    let context: HasSecurityService & HasWalletStorage & HasWalletService
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("wallet", use: getWallet)
    }
}

extension WalletRouteCollection {
    func getWallet(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            fetchBalance() { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: 500), reason: error.localizedDescription))
                    
                case let .success(balance):
                    let address = context.walletStorage.walletAddress
                    let wallet = Wallet(address: address, balance: balance, currency: ClientConstants.denom)
                    
                    Encoder.encode(model: wallet, continuation: continuation)
                }
            }
        })
    }
}

// MARK: - Private

extension WalletRouteCollection {
    private func fetchBalance(
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        context.walletService.fetchBalance { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .success(balances):
                guard let balance = balances.first(where: { $0.denom == ClientConstants.denom }) else {
                    completion(.success(0))
                    return
                }
                
                guard let amount = Int(balance.amount) else {
                    // TODO: Call completion with error
                    
                    return
                }
                
                completion(.success(amount))
            }
        }
    }
}
