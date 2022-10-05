//
//  StartSessionRequest.swift
//  SOLARAPI
//
//  Created by Lika Vorobeva on 26.09.2022.
//

import Foundation

public struct StartSessionRequest: Codable {
    public let key: String
    public let signature: String
    
    public init(key: String, signature: String) {
        self.key = key
        self.signature = signature
    }
}
