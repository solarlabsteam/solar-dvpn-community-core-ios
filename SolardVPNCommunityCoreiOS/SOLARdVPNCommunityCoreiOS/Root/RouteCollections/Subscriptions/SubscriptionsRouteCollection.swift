//
//  SubscriptionsRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 06.10.2022.
//

import Vapor

private struct Constants {
    let path: PathComponent = "subscriptions"
}
private let constants = Constants()

struct SubscriptionsRouteCollection: RouteCollection {
    let context: HasSubscriptionsService
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(constants.path, use: getSubscriptions)
    }
}

extension SubscriptionsRouteCollection {
    func getSubscriptions(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            context.subscriptionsService.loadActiveSubscriptions { result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: 500), reason: error.localizedDescription))
                    
                case let .success(subscriptions):
                    let subscriptions = subscriptions.map { $0.node }
                    let response = Array(Set(subscriptions))
                    
                    Encoder.encode(model: response, continuation: continuation)
                }
            }
        })
    }
}
