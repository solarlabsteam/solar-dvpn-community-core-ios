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
    
    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "empty_name"
        case .nameAlreadyExists:
            return "name_already_exists"
        case .loadTunnelsFailed:
            return "load_tunnels_failed"
        case .addTunnelFailed:
            return "add_tunnel_failed"
        case .removeTunnelFailed:
            return "remove_tunnel_failed"
        }
    }
}

enum TunnelActivationError: LocalizedError {
    case inactive
    case startingFailed(systemError: Error)
    case savingFailed(systemError: Error)
    case loadingFailed(systemError: Error)
    case retryLimitReached(lastSystemError: Error)
    case activationAttemptFailed(wasOnDemandEnabled: Bool)
    
    var errorDescription: String? {
        switch self {
        case .inactive:
            return "inactive"
        case .startingFailed(let systemError):
            return "starting_failed: \(systemError.localizedDescription)"
        case .savingFailed(let systemError):
            return "saving_failed: \(systemError.localizedDescription)"
        case .loadingFailed(let systemError):
            return "loading_failed: \(systemError.localizedDescription)"
        case .retryLimitReached(let lastSystemError):
            return "retry_limit_reached: \(lastSystemError.localizedDescription)"
        case .activationAttemptFailed:
            return "activation_attempt_failed"
        }
    }
}

protocol TunnelsServiceStatusDelegate: AnyObject {
    func activationAttemptFailed(for tunnel: TunnelContainer, with error: TunnelActivationError)
    func activationAttemptSucceeded(for tunnel: TunnelContainer)

    func activationFailed(for tunnel: TunnelContainer, with error: TunnelActivationError)
    func activationSucceeded(for tunnel: TunnelContainer)

    func deactivationSucceeded(for tunnel: TunnelContainer)
}
