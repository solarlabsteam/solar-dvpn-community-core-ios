//
//  TunnelRouteCollection.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Vapor
import Combine

enum TunnelRouteEvent: String {
    case alreadyConnected = "Already Connected"
    case alreadyDisconnected = "Already Disconnected"
    
    var responseStatus: HTTPResponseStatus {
        switch self {
        case .alreadyConnected:
            return .custom(code: 500, reasonPhrase: self.rawValue)
        case .alreadyDisconnected:
            return .custom(code: 200, reasonPhrase: self.rawValue)
        }
    }
    
    var response: Response {
        Response(status: responseStatus)
    }
}

private struct Constants {
    let path: PathComponent = "connection"
    let connectionType = "tunnelStatus"
}
private let constants = Constants()

class TunnelRouteCollection: RouteCollection {
    private let model: ConnectionModel
    private var cancellables = Set<AnyCancellable>()
    
    private weak var delegate: WebSocketDelegate?
    
    init(model: ConnectionModel, delegate: WebSocketDelegate?) {
        self.model = model
        self.delegate = delegate
        
        subscribeToEvents()
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.post(constants.path, use: createNewSession)
        routes.delete(constants.path, use: startDeactivationOfActiveTunnel)
    }
}

extension TunnelRouteCollection {
    func startDeactivationOfActiveTunnel(_ req: Request) -> Response {
        let status = model.disconnect() ? .ok : TunnelRouteEvent.alreadyDisconnected.responseStatus
        return Response(status: status)
    }
    
    func createNewSession(_ req: Request) throws -> Response {
        do {
            let body = try req.content.decode(PostConnectionRequest.self)
            let address = body.nodeAddress
            
            let status = model.connect(to: address) ? .accepted : TunnelRouteEvent.alreadyConnected.responseStatus
            
            return Response(status: status)
        } catch {
            return Response(status: .badRequest)
        }
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
                case let .updateTunnelActivity(isActive):
                    self.updateConnection(isConnected: isActive)
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Handle events
    
extension TunnelRouteCollection {
    private func send(error: SingleInnerError) {
        let data = error.toData()?.string ?? error.error.message
        delegate?.send(event: data)
    }
    
    private func send(warning: SingleInnerError) {
        let data = warning.toData()?.string ?? warning.error.message
        delegate?.send(event: data)
    }
    
    private func updateConnection(isConnected: Bool) {
        log.debug(isConnected)
        let event = InfoEvent(
            type: constants.connectionType,
            value: isConnected ? "connected" : "disconnected"
        )
        if let dataString = event.toData()?.string {
            delegate?.send(event: dataString)
        }
    }
}
