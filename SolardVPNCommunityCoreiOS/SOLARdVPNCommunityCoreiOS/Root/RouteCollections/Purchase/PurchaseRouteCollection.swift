//
//  PurchaseRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 10.10.2022.
//

import Vapor
import RevenueCat

struct PurchaseRouteCollection: RouteCollection {
    typealias Context = HasWalletService
    
    private let context: Context
    
    init(context: Context) {
        self.context = context
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("offerings", use: getOfferings)
        routes.post("purchase", ":identifier", use: postPurchase)
    }
}

extension PurchaseRouteCollection {
    func getOfferings(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            getOfferings() { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: error.encodedError())
                case let .success(offerings):
                    Encoder.encode(model: offerings.map { Offering(from: $0) }, continuation: continuation)
                }
            }
        })
    }
    
    func postPurchase(_ req: Request) async throws -> Response {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Response, Error>) in
            guard let identifier = req.parameters.get("identifier") else {
                continuation.resume(throwing: Abort(.badRequest))
                return
            }
            
            login()

            getOfferings() { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: error.encodedError())
                case let .success(offerings):
                    let package = offerings.flatMap { $0.availablePackages }.first(where: { $0.identifier == identifier })

                    guard let package = package else {
                        continuation.resume(throwing: Abort(.init(statusCode: 500), reason: "Failed to find package"))

                        return
                    }

                    purchase(package: package) { result in
                        switch result {
                        case let .failure(error):
                            continuation.resume(throwing: error.encodedError())
                        case .success:
                            continuation.resume(returning: .init(status: .ok))
                        }
                    }
                }
            }
        })
    }
}

// MARK: - Private

extension PurchaseRouteCollection {
    private func getOfferings(completion: @escaping (Result<[RevenueCat.Offering], Error>) -> Void) {
        Purchases.shared.getOfferings { offerings, error in
            guard let offerings = offerings else {
                if let error = error {
                    log.error(error)
                    completion(.failure(error))
                    return
                }
                
                completion(.success([]))
                return
            }
            
            completion(.success(offerings.all.values.map { $0 }))
        }
    }
    
    private func purchase(package: RevenueCat.Package, completion: @escaping (Result<Void, Error>) -> Void) {
        Purchases.shared.purchase(package: package) { transaction, purchaserInfo, error, userCancelled in
            guard !userCancelled else {
                completion(.failure(PurchasesModelError.purchaseCancelled))
                return
            }

            guard let error = error else {
                completion(.success(()))
                return
            }

            log.error(error)
            completion(.failure(error))
        }
    }
    
    private func login() {
        let appUserID = context.walletService.currentWalletAddress
        
        Purchases.shared.logIn(appUserID) { purchaserInfo, created, error in
            log.info(purchaserInfo)
            log.debug(created)
            
            if let error = error {
                log.error(error)
                return
            }
        }
    }
}

enum PurchasesModelError: LocalizedError {
    case purchaseCancelled
    
    var errorDescription: String? {
        switch self {
        case .purchaseCancelled:
            return "Purchase was canceled."
        }
    }
}
