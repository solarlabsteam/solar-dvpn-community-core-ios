//
//  NodesRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Vapor
import SOLARAPI

struct NodesRouteCollection: RouteCollection {
    let context: HasNodesProvider
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("nodes", use: getNodes)
        routes.post("nodesByAddress", use: postNodesByAddress)
        routes.get("countries", use: getCountries)
    }
}

extension NodesRouteCollection {
    func getNodes(_ req: Request) async throws -> String {
        let continentCode = req.query[String.self, at: GetNodesRequest.CodingKeys.continentCode.rawValue]
        let countryCode = req.query[String.self, at: GetNodesRequest.CodingKeys.countryCode.rawValue]
        let minPrice = req.query[Int.self, at: GetNodesRequest.CodingKeys.minPrice.rawValue]
        let maxPrice = req.query[Int.self, at: GetNodesRequest.CodingKeys.maxPrice.rawValue]
        let orderBy = req.query[OrderType.self, at: GetNodesRequest.CodingKeys.orderBy.rawValue]
        let query = req.query[String.self, at: GetNodesRequest.CodingKeys.query.rawValue]
        let page = req.query[Int.self, at: GetNodesRequest.CodingKeys.page.rawValue]
        
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            context.nodesProvider.getNodes(
                .init(
                    status: .active,
                    continentCode: continentCode,
                    countryCode: countryCode,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    orderBy: orderBy,
                    query: query,
                    page: page
                )
            ) { result in
                switch result {
                case let .success(response):
                    Encoder.encode(model: response, continuation: continuation)
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: error.code), reason: error.localizedDescription))
                }
            }
        })
    }
    
    func postNodesByAddress(_ req: Request) async throws -> String {
        let body = try req.content.decode(NodesByAddressPostBody.self)
        
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            context.nodesProvider.postNodesByAddress(
                .init(addresses: body.blockchain_addresses, page: body.page)
            ) { result in
                switch result {
                case let .success(response):
                    Encoder.encode(model: response, continuation: continuation)
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: error.code), reason: error.localizedDescription))
                }
            }
        })
    }
    
    func getCountries(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            context.nodesProvider.getCountries() { result in
                switch result {
                case let .success(response):
                    Encoder.encode(model: response, continuation: continuation)
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: error.code), reason: error.localizedDescription))
                }
            }
        })
    }
}
