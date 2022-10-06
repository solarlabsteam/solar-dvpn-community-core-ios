//
//  PostSubscribeRequest.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 06.10.2022.
//

import Foundation

struct PostSubscribeRequest: Codable {
    let nodeAddress: String
    let amount: String
    let denom: String
}

// MARK: - Codable implementation

extension PostSubscribeRequest {
    enum CodingKeys: String, CodingKey {
        case nodeAddress = "node_address"
        case amount
        case denom
    }
}
