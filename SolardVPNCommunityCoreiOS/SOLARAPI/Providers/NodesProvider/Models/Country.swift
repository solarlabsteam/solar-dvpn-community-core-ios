//
//  Country.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 03.10.2022.
//

import Foundation

public struct Country: Codable {
    public let code: String
    public let nodesCount: Int
    
    public init(code: String, nodesCount: Int) {
        self.code = code
        self.nodesCount = nodesCount
    }
}

// MARK: - Codable implementation

public extension Country {
    enum CodingKeys: String, CodingKey {
        case code
        case nodesCount = "nodes_count"
    }
}
