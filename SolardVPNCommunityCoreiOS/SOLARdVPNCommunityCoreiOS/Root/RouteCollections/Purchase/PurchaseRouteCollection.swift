//
//  PurchaseRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 10.10.2022.
//

import Vapor
import RevenueCat

struct PurchaseRouteCollection: RouteCollection {
    let context: NoContext
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("offerings", use: getOfferings)
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
                    Encoder.encode(model: offerings, continuation: continuation)
                }
            }
        })
    }
}

// MARK: - Private

extension PurchaseRouteCollection {
    private func getOfferings(completion: @escaping (Result<[Offering], Error>) -> Void) {
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
            
            completion(.success(offerings.all.values.map { Offering(from: $0) }))
        }
    }
}
