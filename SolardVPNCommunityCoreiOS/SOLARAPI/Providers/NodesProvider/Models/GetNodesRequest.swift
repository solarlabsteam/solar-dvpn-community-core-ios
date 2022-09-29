//
//  GetNodesRequest.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

public struct GetNodesRequest: Codable {
    public let status: NodeStatusType
    public let continentCode: String?
    public let countryCode: String?
    public let minPrice: Int?
    public let maxPrice: Int?
    public let orderBy: OrderType?
    public let query: String?
    public let page: Int?

    public init(
        status: NodeStatusType,
        continentCode: String?,
        countryCode: String?,
        minPrice: Int?,
        maxPrice: Int?,
        orderBy: OrderType?,
        query: String?,
        page: Int?
    ) {
        self.status = status
        self.continentCode = continentCode
        self.countryCode = countryCode
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.orderBy = orderBy
        self.query = query
        self.page = page
    }
}

// MARK: - Codable implementation

public extension GetNodesRequest {
    enum CodingKeys: String, CodingKey {
        case status
        case continentCode = "continent"
        case countryCode = "country"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case orderBy = "order_by"
        case query = "q"
        case page
    }
}
