//
//  TunnelRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Vapor
import Combine

enum TunnelRouteEvent: String {
    case alreadyConnected
    case subscriptionCanceled
}

class TunnelRouteCollection: RouteCollection {
    private let model: ConnectionModel
    private var cancellables = Set<AnyCancellable>()
    
    // Connection Status
    @Published private(set) var isConnected: Bool = false
    private weak var delegate: WebSocketDelegate?
    
    init(model: ConnectionModel, delegate: WebSocketDelegate?) {
        self.model = model
        self.delegate = delegate
        
        subscribeToEvents()
        model.setInitData()
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.post("connection", use: createNewSession)
        routes.delete("connection", use: startDeactivationOfActiveTunnel)
    }
}

extension TunnelRouteCollection {
#warning("TODO add result")
    func startDeactivationOfActiveTunnel(_ req: Request) async throws -> Bool {
        model.disconnect()
        
        return true
    }
    
#warning("TODO add result & pass node")
    func createNewSession(_ req: Request) async throws -> Bool {
        if isConnected {
            return true // && add status TunnelRouteEvent
        }
        model.connect()
        return true
    }
}

// MARK: - Subscribe to events

extension TunnelRouteCollection {
    private func subscribeToEvents() {
        model.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case let .error(error):
                    self.send(error: error)
                case let .warning(warning):
                    self.send(warning: warning)
                case let .info(text):
                    self.send(info: text)
                case let .updateTunnelActivity(isActive):
                    self.updateConnection(isConnected: isActive)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Handle events
    
extension TunnelRouteCollection {
    private func send(error: Error) {
#warning("TODO: send json with error")
        delegate?.send(event: error.localizedDescription)
    }
    
    private func send(warning: Error) {
#warning("TODO: send json with warning")
        delegate?.send(event: warning.localizedDescription)
    }
    
    private func send(info: String) {
#warning("TODO: send json with info")
        delegate?.send(event: info)
    }
    
    private func updateConnection(isConnected: Bool) {
#warning("TODO: send json with isConnected")
        self.isConnected = isConnected
        delegate?.send(event: "isConnected \(isConnected)")
    }
}
