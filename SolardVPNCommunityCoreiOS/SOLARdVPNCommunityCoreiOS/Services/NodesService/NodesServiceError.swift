//
//  NodesServiceError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 03.10.2022.
//

import Foundation

enum NodesServiceError: String, LocalizedError {
    case failToLoadData = "fail_to_load_data"
    
    var errorDescription: String? {
        self.rawValue
    }
}
