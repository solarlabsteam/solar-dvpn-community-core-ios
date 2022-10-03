//
//  NodesService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import SOLARAPI
import Vapor

final class NodesService {
    private let nodesProvider: NodesProviderType
    
    init(
        nodesProvider: NodesProviderType
    ) {
        self.nodesProvider = nodesProvider
    }
}

// MARK: - NodesServiceType

extension NodesService: NodesServiceType {
}
