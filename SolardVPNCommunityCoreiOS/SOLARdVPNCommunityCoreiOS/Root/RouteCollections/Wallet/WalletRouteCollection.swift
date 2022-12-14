//
//  WalletRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 04.10.2022.
//

import Foundation
import Vapor
import SentinelWallet

struct WalletRouteCollection: RouteCollection {
    let context: HasSecurityService & HasWalletStorage & HasWalletService & HasDNSServersStorage
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("wallet", use: getWallet)
        routes.put("wallet", use: putWallet)
        routes.post("wallet", use: postWallet)
        routes.delete("wallet", use: deleteWallet)
    }
}

extension WalletRouteCollection {
    func getWallet(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            getWallet() { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: error.encodedError())
                    
                case let .success(wallet):
                    Encoder.encode(model: wallet, continuation: continuation)
                }
            }
        })
    }
    
    func putWallet(_ req: Request) async throws -> String {
         try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
             do {
                 let body = try req.content.decode(Mnemonic.self)
                 let mnemonic = body.mnemonic.components(separatedBy: .whitespaces)
                 
                 switch context.securityService.restore(from: mnemonic) {
                 case .failure(let error):
                     continuation.resume(throwing: error.encodedError())
                     
                 case .success(let result):
                     guard context.securityService.save(mnemonics: mnemonic, for: result) else {
                         continuation.resume(throwing: WalletServiceError.savingError.encodedError())
                         return
                     }
                     context.walletStorage.set(wallet: result)
                     context.updateWalletContext()
                     
                     getWallet() { result in
                         switch result {
                         case let .failure(error):
                             continuation.resume(throwing: error.encodedError())
                             
                         case let .success(wallet):
                             Encoder.encode(model: wallet, continuation: continuation)
                         }
                     }
                 }
             } catch {
                 continuation.resume(throwing: Abort(.badRequest))
             }
         })
    }
    
    func postWallet(_ req: Request) async throws -> String {
        context.resetWalletContext()
        
        let address = context.walletStorage.walletAddress
        
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            guard let mnemonic = context.securityService.loadMnemonics(for: address) else {
                continuation.resume(throwing: WalletServiceError.missingMnemonics.encodedError())
                return
            }
            
            getWallet() { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: error.encodedError())
                case let .success(wallet):
                    let response = PostMnemonicResponse(wallet: wallet, mnemonic: mnemonic.joined(separator: " "))
                    Encoder.encode(model: response, continuation: continuation)
                }
            }
        })
    }

    func deleteWallet(_ req: Request) -> Response {
        context.resetWalletContext()
        
        context.dnsServersStorage.set(dns: .default)
        
        return Response()
    }
}

// MARK: - Private

extension WalletRouteCollection {
    private func getWallet(
        completion: @escaping (Result<Wallet, Error>) -> Void
    ) {
        fetchBalance() { result in
            switch result {
            case let .failure(error):
                completion(.failure(error.encodedError()))
                
            case let .success(balance):
                let address = context.walletStorage.walletAddress
                let wallet = Wallet(address: address, balance: balance, currency: ClientConstants.denom)
                
                completion(.success(wallet))
            }
        }
    }
    
    private func fetchBalance(
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        context.walletService.fetchBalance { result in
            switch result {
            case let .failure(error):
                completion(.failure(error.encodedError()))
                
            case let .success(balances):
                guard let balance = balances.first(where: { $0.denom == ClientConstants.denom }) else {
                    completion(.success(0))
                    return
                }
                
                guard let amount = Int(balance.amount) else {
                    completion(.failure(Abort(.internalServerError)))
                    return
                }
                
                completion(.success(amount))
            }
        }
    }
}
