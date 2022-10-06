//
//  PostDNSResponse.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 06.10.2022.
//

import Foundation

struct PostDNSResponse: Codable {
    let servers: [AvailableDNSServer]
}

struct AvailableDNSServer: Codable {
    let name: String
    let addresses: String
    
    init(from type: DNSServerType)  {
        self.name = type.rawValue
        self.addresses = type.address
    }
}
