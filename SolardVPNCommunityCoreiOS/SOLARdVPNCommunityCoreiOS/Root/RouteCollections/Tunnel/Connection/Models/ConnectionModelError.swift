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

enum ConnectionModelError: String, Error {
    case signatureGenerationFailed
    case nodeIsOffline
    case balanceUpdateFailed
    case noSelectedNode
    case noSubscription
    case noQuotaLeft
    case tunnelIsAlreadyActive
    
    var body: SingleInnerError {
        switch self {
        case .signatureGenerationFailed:
            return .init(code: 500, message: self.rawValue)
        case .nodeIsOffline:
            return .init(code: 500, message: self.rawValue)
        case .balanceUpdateFailed:
            return .init(code: 500, message: self.rawValue)
        case .noSelectedNode:
            return .init(code: 404, message: self.rawValue)
        case .noSubscription:
            return .init(code: 404, message: self.rawValue)
        case .noQuotaLeft:
            return .init(code: 401, message: self.rawValue)
        case .tunnelIsAlreadyActive:
            return .init(code: 500, message: self.rawValue)
        }
    }
}

extension WalletServiceError {
    var body: SingleInnerError {
        switch self {
        case .accountMatchesDestination:
            return .init(code: 403, message: "accountMatchesDestination")
        case .missingMnemonics:
            return .init(code: 401, message: "missingMnemonics")
        case .missingAuthorization:
            return .init(code: 401, message: "missingAuthorization")
        case .notEnoughTokens:
            return .init(code: 402, message: "notEnoughTokens")
        case .mnemonicsDoNotMatch:
            return .init(code: 401, message: "mnemonicsDoNotMatch")
        case .savingError:
            return .init(code: 500, message: "savingError")
        }
    }
}
