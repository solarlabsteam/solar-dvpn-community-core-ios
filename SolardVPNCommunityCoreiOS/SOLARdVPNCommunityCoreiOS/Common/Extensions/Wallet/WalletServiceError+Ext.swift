//
//  WalletServiceError+Ext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 10.10.2022.
//

import Foundation
import SentinelWallet

extension WalletServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .accountMatchesDestination:
            return "account_matches_destination"
        case .missingMnemonics:
            return "missing_mnemonics"
        case .missingAuthorization:
            return "missing_authorization"
        case .notEnoughTokens:
            return "not_enough_tokens"
        case .mnemonicsDoNotMatch:
            return "mnemonic_do_not_match"
        case .savingError:
            return "saving_error"
        }
    }
}

extension WalletServiceError {
    var body: SingleInnerError {
        switch self {
        case .accountMatchesDestination:
            return .init(code: 403, message: localizedDescription)
        case .missingMnemonics:
            return .init(code: 401, message: localizedDescription)
        case .missingAuthorization:
            return .init(code: 401, message: localizedDescription)
        case .notEnoughTokens:
            return .init(code: 402, message: localizedDescription)
        case .mnemonicsDoNotMatch:
            return .init(code: 401, message: localizedDescription)
        case .savingError:
            return .init(code: 500, message: localizedDescription)
        }
    }
}
