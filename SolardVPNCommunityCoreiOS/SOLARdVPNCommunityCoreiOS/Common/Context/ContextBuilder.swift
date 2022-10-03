//
//  ContextBuilder.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 29.09.2022.
//

import Foundation
import SOLARAPI

/// This class should configure all required services and inject them into a Context
final class ContextBuilder {
    func buildContext() -> CommonContext {
        let nodesProvider = NodesProvider(configuration: .init(baseURL: ClientConstants.backendURL))
        
        let nodesService = NodesService(nodesProvider: nodesProvider)
        
        return CommonContext(
            nodesProvider: nodesProvider,
            nodesService: nodesService
        )
    }
}
