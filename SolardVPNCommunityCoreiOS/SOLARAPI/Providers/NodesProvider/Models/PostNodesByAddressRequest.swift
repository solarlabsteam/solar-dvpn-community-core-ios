//
//  PostNodesByAddressRequest.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 30.09.2022.
//

import Foundation

public struct PostNodesByAddressRequest: Codable {
    let addresses: [String]
    let page: Int?

    public init(addresses: [String], page: Int?) {
        self.addresses = addresses
        self.page = page
    }
}

// MARK: - Codable implementation

public extension PostNodesByAddressRequest {
    enum CodingKeys: String, CodingKey {
        case addresses = "blockchain_addresses"
        case page
    }
}
