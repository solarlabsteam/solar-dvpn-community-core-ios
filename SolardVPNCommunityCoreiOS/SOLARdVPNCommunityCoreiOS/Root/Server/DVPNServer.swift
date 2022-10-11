//
//  DVPNServer.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 26.09.2022.
//

import Vapor

class DVPNServer: ObservableObject {
    let app: Application
    private var currentClientConnection: WebSocket?
    private let context: CommonContext
    
    init(context: CommonContext) {
        app = Application(.development)
        self.context = context
        Config.setup()
        
        configure(app)
    }
}

extension DVPNServer {
    func start() {
        Task(priority: .background) {
            do {
                let api = app.grouped(.init(stringLiteral: ClientConstants.apiPath))
                try api.register(collection: NodesRouteCollection(context: context))
                try api.register(collection: WalletRouteCollection(context: context))
                try api.register(collection: DNSRouteCollection(context: context))
                try api.register(collection: SubscriptionsRouteCollection(context: context))
                try api.register(collection: StorageRouteCollection(context: context))
                try api.register(
                    collection:
                        TunnelRouteCollection(
                            context: context,
                            model: ConnectionModel(context: context),
                            delegate: self
                        )
                )
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
        
        configureConnection()
    }
    
    private func configureConnection() {
        app.webSocket("echo") { [weak self] req, client in
            client.pingInterval = .seconds(5)
            self?.currentClientConnection = client
            
            client.onClose.whenComplete { _ in
                self?.currentClientConnection = nil
            }
            
            client.onText { ws, text in
                log.debug(text)
            }
        }
    }
}

// MARK: - WebSocketDelegate

extension DVPNServer: WebSocketDelegate {
    func send(event: String) {
        currentClientConnection?.send(event)
    }
}
