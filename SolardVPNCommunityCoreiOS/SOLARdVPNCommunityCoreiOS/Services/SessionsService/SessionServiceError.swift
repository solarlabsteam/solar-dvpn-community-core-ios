//
//  SessionsServiceError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 29.11.2021.
//

import Foundation

enum SessionsServiceError: LocalizedError {
    case invalidURL
    
    case connectionParsingFailed
    case nodeMisconfigured
    case noQuota
    
    case serverLocalized(String)
    case other(Error)
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
