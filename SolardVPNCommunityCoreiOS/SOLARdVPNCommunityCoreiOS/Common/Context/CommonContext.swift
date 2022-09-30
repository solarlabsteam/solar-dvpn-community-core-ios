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
    let tunnelManager: TunnelManagerType
    
    init(
        nodesService: NodesServiceType,
        tunnelManager: TunnelManagerType
    ) {
        self.nodesService = nodesService
        self.tunnelManager = tunnelManager
    }
}

protocol HasNodesService { var nodesService: NodesServiceType { get } }
extension CommonContext: HasNodesService {}

protocol HasTunnelManager { var tunnelManager: TunnelManagerType { get } }
extension CommonContext: HasTunnelManager {}
