//
//  NodesRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Vapor
import SOLARAPI

struct NodesRouteCollection: RouteCollection {
    let context: HasNodesProvider & HasNodesService
    
    func boot(routes: RoutesBuilder) throws {
        routes.get("nodes", use: getNodes)
        routes.post("nodesByAddress", use: postNodesByAddress)
        routes.get("countries", use: getCountries)
        routes.get("continents", use: getContinents)
        routes.get("countriesByContinent", use: getCountriesByContinent)
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
                    continuation.resume(throwing: error.encodedError())
                }
            }
        })
    }
    
    func postNodesByAddress(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            do {
                let body = try req.content.decode(NodesByAddressPostBody.self)
                let addresses = Array(Set(body.blockchain_addresses))
                
                context.nodesProvider.postNodesByAddress(
                    .init(addresses: addresses, page: body.page)
                ) { result in
                    switch result {
                    case let .success(response):
                        Encoder.encode(model: response, continuation: continuation)
                    case let .failure(error):
                        continuation.resume(throwing: error.encodedError())
                    }
                }
            } catch {
                continuation.resume(throwing: Abort(.badRequest))
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
                    continuation.resume(throwing: error.encodedError())
                }
            }
        })
    }
    
    func getContinents(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            let response = context.nodesService.nodesInContinentsCount
                .map { GetContinentResponse(code: $0.key.rawValue, nodesCount: $0.value) }
            
            Encoder.encode(model: response, continuation: continuation)
        })
    }
    
    func getCountriesByContinent(_ req: Request) async throws -> String {
        let continentCode = req.query[String.self, at: "continent"]
        
        guard let continent = Continent(rawValue: continentCode ?? "") else {
            throw Abort(.badRequest)
        }
        
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            let response = context.nodesService.countriesInContinents[continent]
            Encoder.encode(model: response, continuation: continuation)
        })
    }
}
