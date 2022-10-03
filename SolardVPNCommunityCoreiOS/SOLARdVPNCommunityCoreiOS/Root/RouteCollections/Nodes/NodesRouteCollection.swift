//
//  NodesRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Vapor

struct NodesRouteCollection: RouteCollection {
    let context: HasNodesService
    
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
        
        return try await context.nodesService.loadNodes(
            continentCode: continentCode,
            countryCode: countryCode,
            minPrice: minPrice,
            maxPrice: maxPrice,
            orderBy: orderBy,
            query: query,
            page: page
        )
    }
    
    func postNodesByAddress(_ req: Request) async throws -> String {
        let body = try req.content.decode(NodesByAddressPostBody.self)
        
        return try await context.nodesService.getNodes(
            by: body.blockchain_addresses,
            page: body.page
        )
    }
    
    func getCountries(_ req: Request) async throws -> String {
        try await context.nodesService.getCountries()
    }
}
