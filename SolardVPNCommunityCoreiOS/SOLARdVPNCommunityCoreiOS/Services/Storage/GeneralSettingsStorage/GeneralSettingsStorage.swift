//
//  GeneralSettingsStorage.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import Accessibility

private enum Keys: String, CaseIterable {
    case walletKey
    case dnsKey
    
    case lastSelectedNodeKey
    case lastSessionKey
    case sessionStart
}

final class GeneralSettingsStorage {
    private let settingsStorageStrategy: SettingsStorageStrategyType
    
    @Published private(set) var _preselectedNode: String?

    init(settingsStorageStrategy: SettingsStorageStrategyType = UserDefaultsStorageStrategy()) {
        self.settingsStorageStrategy = settingsStorageStrategy
    }
}

// MARK: - StoresWallet

extension GeneralSettingsStorage: StoresWallet {
    func set(wallet: String) {
        settingsStorageStrategy.setObject(wallet, forKey: Keys.walletKey.rawValue)
    }
    
    var walletAddress: String {
        settingsStorageStrategy.object(ofType: String.self, forKey: Keys.walletKey.rawValue) ?? ""
    }
}

// MARK: - StoresDNSServers

extension GeneralSettingsStorage: StoresDNSServers {
    func set(dns: DNSServerType) {
        settingsStorageStrategy.setObject(dns.rawValue, forKey: Keys.dnsKey.rawValue)
    }
    
    var selectedDNS: DNSServerType {
        guard let rawValue = settingsStorageStrategy.object(ofType: String.self, forKey: Keys.dnsKey.rawValue) else {
            return .default
        }

        guard let server = DNSServerType(rawValue: rawValue) else {
            return .default
        }

        return server
    }
}

// MARK: - StoresConnectInfo

extension GeneralSettingsStorage: StoresConnectInfo {
    func set(lastSelectedNode: String?) {
        settingsStorageStrategy.setObject(lastSelectedNode, forKey: Keys.lastSelectedNodeKey.rawValue)
    }

    func lastSelectedNode() -> String? {
        settingsStorageStrategy.object(ofType: String.self, forKey: Keys.lastSelectedNodeKey.rawValue)
    }

    func set(sessionId: Int?) {
        settingsStorageStrategy.setObject(sessionId, forKey: Keys.lastSessionKey.rawValue)
    }

    func lastSessionId() -> Int? {
        settingsStorageStrategy.object(ofType: Int.self, forKey: Keys.lastSessionKey.rawValue)
    }
    
    func set(sessionStart: Date?) {
        settingsStorageStrategy.setObject(sessionStart, forKey: Keys.sessionStart.rawValue)
    }
    
    func lastSessionStart() -> Date? {
        settingsStorageStrategy.object(ofType: Date.self, forKey: Keys.sessionStart.rawValue)
    }
}
