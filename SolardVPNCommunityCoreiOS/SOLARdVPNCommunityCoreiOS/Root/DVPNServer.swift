//
//  DVPNServer.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 26.09.2022.
//

import Vapor

class DVPNServer: ObservableObject {
    let app: Application
    private let context: CommonContext
    
    init(context: CommonContext) {
        app = Application(.development)
        self.context = context
        
        configure(app)
    }
}

extension DVPNServer {
    func start() {
        Task(priority: .background) {
            do {
                let api = app.grouped(.init(stringLiteral: ClientConstants.apiPath))
                try api.register(collection: NodesRouteCollection(context: context))
                try api.register(collection: TunnelRouteCollection(context: context))
                try app.start()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
}

// MARK: - Private

extension DVPNServer {
    private func configure(_ app: Application) {
        app.http.server.configuration.hostname = ClientConstants.host
        app.http.server.configuration.port = ClientConstants.port
    }
}
