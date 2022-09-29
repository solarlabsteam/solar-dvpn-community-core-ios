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
        routes.get(.init(stringLiteral: ClientConstants.apiPath), "nodes", use: getNodes)
    }
}

extension NodesRouteCollection {
    // TODO: Add parameters
    func getNodes(_ req: Request) async throws -> String {
        try await context.nodesService.loadNodes(
            continent: nil,
            countryCode: nil,
            minPrice: nil,
            maxPrice: nil,
            orderBy: nil,
            query: nil,
            page: nil
        )
    }
}
