//
//  KeychainStorageStrategy.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import KeychainAccess

// MARK: - KeychainStorageStrategy

final class KeychainStorageStrategy {
    private let keychain: KeychainAccess.Keychain
    
    init(serviceKey: String) {
        self.keychain = KeychainAccess.Keychain(service: serviceKey)
    }
}

extension KeychainStorageStrategy: SettingsStorageStrategyType {
    func object<T: Codable>(ofType type: T.Type, forKey key: String) -> T? {
        if let data = try? keychain.getData(key),
            let object = Serializer.fromData(data, withType: type.self) {
            return object
        }
        return nil
    }

    func setObject<T: Codable>(_ object: T, forKey key: String) -> Bool {
        if let encoded = object.toData() {
            do {
                try keychain.set(encoded, key: key)
                return true
            } catch {
                return false
            }
        }
        return false
    }

    func existsObject(forKey key: String) -> Bool {
        return (try? keychain.getData(key)) != nil
    }

    func removeObject(forKey key: String) -> Bool {
        do {
            try keychain.remove(key)
            return true
        } catch {
            return false
        }
    }
}
