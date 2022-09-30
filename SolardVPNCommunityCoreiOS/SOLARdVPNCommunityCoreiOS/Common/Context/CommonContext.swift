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
    let nodesService: NodesServiceType
    
    init(
        nodesService: NodesServiceType
    ) {
        self.nodesService = nodesService
    }
}

protocol HasNodesService { var nodesService: NodesServiceType { get } }
extension CommonContext: HasNodesService {}
