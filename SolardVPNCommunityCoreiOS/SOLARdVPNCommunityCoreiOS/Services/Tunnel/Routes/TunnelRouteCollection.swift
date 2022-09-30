//
//  TunnelRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Vapor

struct TunnelRouteCollection: RouteCollection {
    let context: HasTunnelManager
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("connection", use: createNewSession)
        routes.delete("connection", use: startDeactivationOfActiveTunnel)
    }
}

extension TunnelRouteCollection {
    func startDeactivationOfActiveTunnel(_ req: Request) async throws -> Bool {
        return !context.tunnelManager.startDeactivationOfActiveTunnel()
    }
    
    func createNewSession(_ req: Request) async throws -> Bool {
        let continentCode = req.query[String.self, at: PostConnectionRequest.CodingKeys.nodeAddress.rawValue]
        
        return true
    }
}
