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
    let error = "error"
}
private let constants = Constants()

class TunnelRouteCollection: RouteCollection {
    typealias Context = HasTunnelManager & HasSessionsService & HasConnectionInfoStorage
    private let context: Context
    private let model: ConnectionModel
    private var cancellables = Set<AnyCancellable>()
    
    private weak var delegate: WebSocketDelegate?
    
    init(context: Context, model: ConnectionModel, delegate: WebSocketDelegate?) {
        self.context = context
        self.model = model
        self.delegate = delegate
        
        subscribeToEvents()
    }
    
    func boot(routes: RoutesBuilder) throws {
        routes.post(constants.path, use: createNewSession)
        routes.delete(constants.path, use: startDeactivationOfActiveTunnel)
        routes.get(constants.path, use: getConnectionStatus)
        routes.delete(constants.path, "configuration", use: resetVPNConfiguration)
        routes.delete(constants.path, "sessions", use: stopActiveSessions)
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
    
    func getConnectionStatus(_ req: Request) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            let isConnected = context.tunnelManager.isTunnelActive
            let nodeAddress = context.connectionInfoStorage.lastSelectedNode() ?? ""
            
            let response = ConnectionStatusResponse(
                tunnelStatus: isConnected ? ConnectionStatusType.connected.rawValue : ConnectionStatusType.disconnected.rawValue,
                nodeAddress: nodeAddress
            )
            
            return Encoder.encode(model: response, continuation: continuation)
        })
    }
    
    func resetVPNConfiguration(_ req: Request) async throws -> Response {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Response, Error>) in
            context.tunnelManager.resetVPNConfiguration { error in
                if let error = error {
                    continuation.resume(throwing: error.encodedError())
                    return
                }
                continuation.resume(returning: Response(status: .ok))
            }
        })
    }
    
    func stopActiveSessions(_ req: Request) async throws -> Response {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Response, Error>) in
            context.sessionsService.stopActiveSessions { [weak self] result in
                switch result {
                case let .failure(error):
                    continuation.resume(throwing: error.encodedError())
                case .success:
                    continuation.resume(returning: Response(status: .ok))
                    self?.context.tunnelManager.startDeactivationOfActiveTunnel()
                }
            }
        })
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
        let message = error.error.toData()?.string ?? error.error.message
        send(key: constants.error, value: message)
    }
    
    private func send(warning: SingleInnerError) {
        let message = warning.error.toData()?.string ?? warning.error.message
        send(key: constants.error, value: message)
    }
    
    private func updateConnection(isConnected: Bool) {
        send(
            key: constants.connectionType,
            value: isConnected ? ConnectionStatusType.connected.rawValue : ConnectionStatusType.disconnected.rawValue
        )
    }
    
    private func send(key: String, value: String) {
        let event = InfoEvent(
            type: key,
            value: value
        )
        if let dataString = event.toData()?.string {
            delegate?.send(event: dataString)
        }
    }
}
