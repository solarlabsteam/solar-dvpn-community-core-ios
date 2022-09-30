//
//  Node.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

public struct Node: Codable {
    public let id: Int
    public let address: String
    public let isTrusted: Bool
    public let moniker: String?
    public let countryCode: String?
    public let continentCode: String?
    public let bandwidthUpload: Int
    public let bandwidthDownload: Int
    public let price: Int
    public let status: NodeStatusType
    public let remoteURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case address = "blockchain_address"
        case isTrusted = "is_trusted"
        case moniker
        case countryCode = "location_country_code"
        case continentCode = "location_continent_code"
        case bandwidthUpload = "bandwidth_upload"
        case bandwidthDownload = "bandwidth_download"
        case price = "default_price"
        case status
        case remoteURL = "remote_url"
    }
}
