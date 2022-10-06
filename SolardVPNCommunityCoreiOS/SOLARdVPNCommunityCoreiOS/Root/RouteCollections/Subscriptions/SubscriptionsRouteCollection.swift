//
//  SubscriptionsRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 06.10.2022.
//

import Vapor
import SentinelWallet

private struct Constants {
    let path: PathComponent = "subscriptions"
}
private let constants = Constants()

struct SubscriptionsRouteCollection: RouteCollection {
    let context: HasSubscriptionsService
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(constants.path, use: getSubscriptions)
        routes.post(constants.path, use: subscribe)
        routes.delete(constants.path, use: unsubscribe)
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
    
    func subscribe(_ req: Request) async throws -> Response {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Response, Error>) in
            do {
                let node = try req.content.decode(PostSubscribeRequest.self)
                
                context.subscriptionsService.checkBalanceAndSubscribe(
                    to: node.nodeAddress,
                    deposit: CoinToken(denom: node.denom, amount: node.amount)
                ) { result in
                    switch result {
                    case let .failure(error):
                        continuation.resume(throwing: Abort(.init(statusCode: 401), reason: error.localizedDescription))
                        
                    case let .success(result):
                        guard result else {
                            continuation.resume(throwing: Abort(.paymentRequired))
                            return
                        }
                        
                        continuation.resume(returning: .init(status: .ok))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }
    
    func unsubscribe(_ req: Request) async throws -> Response {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Response, Error>) in
            do {
                guard let nodeAddress = req.query[
                    String.self,
                    at: PostConnectionRequest.CodingKeys.nodeAddress.rawValue
                ] else { throw Abort(.badRequest) }
                
                context.subscriptionsService.loadActiveSubscriptions { result in
                    switch result {
                    case let .success(subscriptions):
                        let subscriptionsToCancel = subscriptions.filter { $0.node == nodeAddress }.map { $0.id }
                        
                        context.subscriptionsService.cancel(
                            subscriptions: subscriptionsToCancel,
                            with: nodeAddress
                        ) { result in
                            switch result {
                            case let .failure(error):
                                continuation.resume(
                                    throwing: Abort(.init(statusCode: 500), reason: error.localizedDescription)
                                )
                            case .success:
                                continuation.resume(returning: Response(status: .ok))
                            }
                        }
                    case let .failure(error):
                        continuation.resume(throwing: Abort(.init(statusCode: 500), reason: error.localizedDescription))
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }
}
