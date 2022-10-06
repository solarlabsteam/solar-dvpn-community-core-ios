//
//  DNSRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 06.10.2022.
//

import Foundation
import Vapor

private struct Constants {
    let path: PathComponent = "dns"
}
private let constants = Constants()

struct DNSRouteCollection: RouteCollection {
    let context: HasDNSServersStorage & HasTunnelManager
    
    func boot(routes: RoutesBuilder) throws {
        routes.get(constants.path, use: getAvailableDNS)
        routes.put(constants.path, use: putDNS)
    }
}

extension DNSRouteCollection {
    func getAvailableDNS(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            let servers = DNSServerType.allCases.map { AvailableDNSServer(name: $0.rawValue, addresses: $0.address) }
            let body = PostDNSResponse(servers: servers)
            
            Encoder.encode(model: body, continuation: continuation)
        })
    }
    
    func putDNS(_ req: Request) throws -> Response {
        do {
            let body = try req.content.decode(PostDNSRequest.self)
            let server = body.server
            
            guard let type = DNSServerType(rawValue: server) else {
                return Response(status: .badRequest)
            }
            context.dnsServersStorage.set(dns: type)
            context.tunnelManager.update(with: type.address)
            return Response(status: .ok)
        } catch {
            return Response(status: .badRequest)
        }
    }
}


