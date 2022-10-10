//
//  SecurityService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 05.10.2022.
//

import Foundation
import SentinelWallet
import HDWallet
import SwiftKeychainWrapper

enum SecurityServiceError: String, Error {
    case emptyInput = "empty_input"
    case invalidInput = "invalid_input"
    
    var errorDescription: String? {
        self.rawValue
    }
}

private struct Constants {
    let key = "password"
    let mnemonicsCount = 24
}
private let constants = Constants()

final public class SecurityService: SecurityServiceType {
    private let keychain: KeychainWrapper

    public init(
        keychain: KeychainWrapper = .init(
            serviceName: "SecurityService",
            accessGroup: "group.ee.solarlabs.community-core.ios"
        )
    ) {
        self.keychain = keychain
    }

    public func save(mnemonics: [String], for account: String) -> Bool {
        let mnemonicString = mnemonics.joined(separator: " ")
        return keychain.set(
            mnemonicString,
            forKey: account.sha1(),
            withAccessibility: .afterFirstUnlockThisDeviceOnly
        )
    }

    public func loadMnemonics(for account: String) -> [String]? {
        keychain
            .string(forKey: account.sha1())?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
    }

    public func mnemonicsExists(for account: String) -> Bool {
        keychain.hasValue(forKey: account.sha1())
    }

    public func restore(from mnemonics: [String]) -> Result<String, Error> {
        guard !mnemonics.isEmpty else {
            return .failure(SecurityServiceError.emptyInput)
        }

        guard
            mnemonics.count == constants.mnemonicsCount, mnemonics.allSatisfy({ WordList.english.words.contains($0) })
        else {
            return .failure(SecurityServiceError.invalidInput)
        }

        guard let restoredAddress = restoreAddress(for: mnemonics) else {
            return .failure(SecurityServiceError.invalidInput)
        }

        return .success(restoredAddress)
    }
}
