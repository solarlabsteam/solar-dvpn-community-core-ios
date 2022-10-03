//
//  NodesServiceType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import SOLARAPI

protocol NodesServiceType {
    func loadNodes(
        continentCode: String?,
        countryCode: String?,
        minPrice: Int?,
        maxPrice: Int?,
        orderBy: OrderType?,
        query: String?,
        page: Int?
    ) async throws -> String
    
    func getNodes(
        by: [String],
        page: Int?
    ) async throws -> String
}
