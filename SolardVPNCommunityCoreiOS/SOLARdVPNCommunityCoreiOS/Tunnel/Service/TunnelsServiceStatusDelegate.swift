//
//  TunnelsServiceStatusDelegate.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//
import Foundation
import WireGuardKit

public enum TunnelsServiceError: LocalizedError {
    case emptyName
    case nameAlreadyExists

    case loadTunnelsFailed(systemError: Error)
    case addTunnelFailed(systemError: Error)
    
    case removeTunnelFailed(systemError: Error)
}

extension TunnelsServiceError {
    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "The name of the tunnel is empty"
        case .nameAlreadyExists:
            return "The name of the tunnel already exist"
        case .loadTunnelsFailed:
            return "Fail to load a tunnel"
        case .addTunnelFailed:
            return "Fail to add a tunnel"
        case .removeTunnelFailed:
            return "Fail to remove the tunnel"
        }
    }
}

enum TunnelActivationError: Error {
    case inactive
    case startingFailed(systemError: Error)
    case savingFailed(systemError: Error)
    case loadingFailed(systemError: Error)
    case retryLimitReached(lastSystemError: Error)
    case activationAttemptFailed(wasOnDemandEnabled: Bool)
}

protocol TunnelsServiceStatusDelegate: AnyObject {
    func activationAttemptFailed(for tunnel: TunnelContainer, with error: TunnelActivationError)
    func activationAttemptSucceeded(for tunnel: TunnelContainer)

    func activationFailed(for tunnel: TunnelContainer, with error: TunnelActivationError)
    func activationSucceeded(for tunnel: TunnelContainer)

    func deactivationSucceeded(for tunnel: TunnelContainer)
}
