//
//  PostDNSRequest.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 06.10.2022.
//

import Foundation

struct PostDNSRequest: Codable {
    let server: String

    init(server: String) {
        self.server = server
    }
}

// MARK: - Codable implementation

extension PostDNSRequest {
    enum CodingKeys: String, CodingKey {
        case server
    }
}
