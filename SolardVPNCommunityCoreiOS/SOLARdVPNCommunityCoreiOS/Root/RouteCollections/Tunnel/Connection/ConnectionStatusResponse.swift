//
//  ConnectionStatusResponse.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 14.10.2022.
//

import Foundation

struct ConnectionStatusResponse {
    let tunnelStatus: String
    let nodeAddress: String
}

extension ConnectionStatusResponse: Codable {}
