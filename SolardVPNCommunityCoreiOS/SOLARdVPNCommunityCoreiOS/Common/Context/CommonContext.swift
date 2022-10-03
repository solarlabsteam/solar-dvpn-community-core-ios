//
//  CommonContext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 29.09.2022.
//

import Foundation
import SOLARAPI

protocol NoContext {}

final class CommonContext {
    // Providers
    let nodesProvider: NodesProviderType
    
    // Services
    let nodesService: NodesServiceType
    
    init(
        nodesProvider: NodesProviderType,
        nodesService: NodesServiceType
    ) {
        self.nodesProvider = nodesProvider
        self.nodesService = nodesService
    }
}

protocol HasNodesProvider { var nodesProvider: NodesProviderType { get } }
extension CommonContext: HasNodesProvider {}

protocol HasNodesService { var nodesService: NodesServiceType { get } }
extension CommonContext: HasNodesService {}
