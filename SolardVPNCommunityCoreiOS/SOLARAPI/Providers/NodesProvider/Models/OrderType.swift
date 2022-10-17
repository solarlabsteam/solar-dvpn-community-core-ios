//
//  OrderType.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

public enum OrderType: String {
    case price = "PRICE"
    case downloadSpeed = "DOWNLOAD_SPEED"
    case uploadSpeed = "UPLOAD_SPEED"
    case peers = "PEERS"
}

extension OrderType: CaseIterable {}

extension OrderType: Codable {}
