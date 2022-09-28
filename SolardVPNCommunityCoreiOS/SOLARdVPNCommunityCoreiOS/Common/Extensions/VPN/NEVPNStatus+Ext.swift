//
//  NEVPNStatus+Ext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation
import NetworkExtension

extension NEVPNStatus {
    var description: String {
        switch self {
        case .connected:
            return "connected"
        case .connecting:
            return "connecting"
        case .disconnected:
            return "disconnected"
        case .disconnecting:
            return "disconnecting"
        case .invalid:
            return "invalid"
        case .reasserting:
            return "reasserting"
        @unknown default:
            return "@unknown default"
        }
    }
}
