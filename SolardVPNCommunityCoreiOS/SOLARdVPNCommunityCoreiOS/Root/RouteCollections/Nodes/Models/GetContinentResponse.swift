//
//  GetContinentResponse.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 03.10.2022.
//

import Foundation

struct GetContinentResponse: Codable {
    let code: String
    let nodesCount: Int
}

// MARK: - Codable implementation

extension GetContinentResponse {
    enum CodingKeys: String, CodingKey {
        case code
        case nodesCount = "nodes_count"
    }
}
