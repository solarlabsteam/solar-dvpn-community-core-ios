//
//  SubscriptionsProviderError+Ext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 17.10.2022.
//

import Foundation
import SentinelWallet

extension SubscriptionsProviderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .broadcastFailed:
            return "broadcast_failed"
        case .sessionStartFailed:
            return "session_start_failed"
        case .sessionsStopFailed:
            return "sessions_stop_failed"
        }
    }
}
