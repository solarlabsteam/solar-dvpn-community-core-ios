//
//  DNSServerType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

enum DNSServerType: String, CaseIterable {
    case handshake
    case google
    case cloudflare

    var address: String {
        switch self {
        case .cloudflare:
            return "1.1.1.1, 1.0.0.1"
        case .google:
            return "8.8.8.8, 8.8.4.4"
        case .handshake:
            return "103.196.38.38, 103.196.38.39"
        }
    }

    static var `default`: DNSServerType {
        .handshake
    }
}
