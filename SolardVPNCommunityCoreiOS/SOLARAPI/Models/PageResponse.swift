//
//  PageResponse.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

public struct PageResponse<Element: Codable>: Codable {
    public let currentPage: Int
    public let data: [Element]
    public let total: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case data = "data"
        case total
    }
}
