//
//  ClientConstants.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Foundation
import SentinelWallet

enum ClientConstants {
    static let host = "localhost"
    static let port = 3876
    
    static let defaultLCDHostString = "lcd-sentinel.dvpn.solar"
    static let defaultLCDPort = 993
    
    static let apiPath = "api"
    
    static let backendURL = URL(string: "https://BACKEND")!
}

final class ApplicationConfiguration: ClientConnectionConfigurationType {
    private(set) static var shared = ApplicationConfiguration()
    
    var grpcMirror: ClientConnectionConfiguration = .init(
        host: ClientConstants.defaultLCDHostString,
        port: ClientConstants.defaultLCDPort
    )
}
