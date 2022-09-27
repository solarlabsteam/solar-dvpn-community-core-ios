//
//  NodesRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Vapor

struct NodesRouteCollection: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: getNodes)
        routes.get(.init(stringLiteral: ClientConstants.apiPath), "nodes", use: getNodes)
    }
}

extension NodesRouteCollection {
    func getNodes(_ req: Request) async throws -> Int {
        
        return 1
    }
}
