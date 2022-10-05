//
//  PostConnectionRequest.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation

struct PostConnectionRequest: Codable {
    let nodeAddress: String

    init(nodeAddress: String) {
        self.nodeAddress = nodeAddress
    }
}

// MARK: - Codable implementation

extension PostConnectionRequest {
    enum CodingKeys: String, CodingKey {
        case nodeAddress = "node_address"
    }
}
