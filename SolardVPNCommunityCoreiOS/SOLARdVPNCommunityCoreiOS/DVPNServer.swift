//
//  DVPNServer.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 26.09.2022.
//

import Vapor

class DVPNServer: ObservableObject {
    let app: Application
    
    init() {
        app = Application(.development)
        configure(app)
    }
}

extension DVPNServer {
    func start() {
        Task(priority: .background) {
            do {
                try app.register(collection: NodesRouteCollection())
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
