//
//  StoresDNSServers.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

protocol StoresDNSServers {
    func set(dns: DNSServerType)
    var selectedDNS: DNSServerType { get }
}
