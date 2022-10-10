//
//  SubscriptionsRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 06.10.2022.
//

import Vapor
import SentinelWallet
import SOLARAPI

private struct Constants {
    let path: PathComponent = "subscriptions"
}
private let constants = Constants()

struct SubscriptionsRouteCollection: RouteCollection {
    let context: HasSubscriptionsService
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(constants.path, use: getSubscriptions)
        routes.get(constants.path, ":node", use: getQuota)
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
                    continuation.resume(throwing: error.encodedError())
                    
                case let .success(subscriptions):
                    let subscriptions = subscriptions.map { $0.node }
                    let response = Array(Set(subscriptions))
                    
                    Encoder.encode(model: response, continuation: continuation)
                }
            }
        })
    }
    
    func getQuota(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            guard let node = req.parameters.get("node") else {
                continuation.resume(throwing: Abort(.badRequest))
                return
            }
            
            context.subscriptionsService.loadActiveSubscriptions { result in
                switch result {
                case let .success(subscriptions):
                    guard let subscription = subscriptions.last(where: { $0.node == node })?.id else {
                        continuation.resume(throwing: Abort(.notFound))
                        return
                    }
                    
                    context.subscriptionsService.queryQuota(for: subscription) { result in
                        switch result {
                        case let .failure(error):
                            continuation.resume(throwing: error.encodedError())
                            
                        case let .success(quota):
                            Encoder.encode(model: quota, continuation: continuation)
                        }
                    }
                case let .failure(error):
                    continuation.resume(throwing: error.encodedError())
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
                    deposit: CoinToken(denom: node.currency, amount: node.amount)
                ) { result in
                    switch result {
                    case let .failure(error):
                        continuation.resume(throwing: error.encodedError(status: 401))
                        
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
                        guard !subscriptionsToCancel.isEmpty else {
                            continuation.resume(throwing: Abort(.notFound))
                            return
                        }
                        
                        context.subscriptionsService.cancel(
                            subscriptions: subscriptionsToCancel,
                            with: nodeAddress
                        ) { result in
                            switch result {
                            case let .failure(error):
                                continuation.resume(throwing: error.encodedError())
                            case .success:
                                continuation.resume(returning: Response(status: .ok))
                            }
                        }
                    case let .failure(error):
                        continuation.resume(throwing: error.encodedError())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        })
    }
}
