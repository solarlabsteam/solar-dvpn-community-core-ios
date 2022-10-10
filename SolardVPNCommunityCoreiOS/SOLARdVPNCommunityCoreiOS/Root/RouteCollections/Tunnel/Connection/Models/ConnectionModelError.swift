//
//  ConnectionModelError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation
import SOLARAPI
import SentinelWallet

typealias SingleInnerError = SOLARAPI.SingleInnerError
typealias InnerError = SOLARAPI.InnerError

enum ConnectionModelError: String, Error {
    case signatureGenerationFailed = "signature_generation_failed"
    case nodeIsOffline = "node_is_offline"
    case balanceUpdateFailed = "balance_update_failed"
    case noSubscription = "no_subscription"
    case noQuotaLeft = "no_quota_left"
    case tunnelIsAlreadyActive = "tunnel_is_already_active"
    
    var body: SingleInnerError {
        switch self {
        case .signatureGenerationFailed:
            return .init(code: 500, message: self.rawValue)
        case .nodeIsOffline:
            return .init(code: 500, message: self.rawValue)
        case .balanceUpdateFailed:
            return .init(code: 500, message: self.rawValue)
        case .noSubscription:
            return .init(code: 404, message: self.rawValue)
        case .noQuotaLeft:
            return .init(code: 401, message: self.rawValue)
        case .tunnelIsAlreadyActive:
            return .init(code: 500, message: self.rawValue)
        }
    }
}
