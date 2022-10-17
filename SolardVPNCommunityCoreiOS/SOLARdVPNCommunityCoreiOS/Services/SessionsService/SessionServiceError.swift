//
//  SessionsServiceError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 29.11.2021.
//

import Foundation

enum SessionsServiceError: String, LocalizedError {
    case invalidURL = "invalid_url"
    
    case connectionParsingFailed = "connection_parsing_failed"
    case nodeMisconfigured = "node_misconfigured"
    case noQuota = "no_quota"
    
    var errorDescription: String? {
        self.rawValue
    }
}

extension SessionsServiceError {
    static var allCases: [SessionsServiceError] {
        [.connectionParsingFailed, .nodeMisconfigured, .noQuota]
    }
    
    var innerCodes: [Int] {
        switch self {
        case .nodeMisconfigured:
            return [3, 4, 5]
        case .noQuota:
            return [9, 10]
        case .connectionParsingFailed:
            return [6, 7, 8]
        default:
            return []
        }
    }
}
