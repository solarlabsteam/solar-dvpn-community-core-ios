//
//  SavingError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

enum TunnelSavingError: Error {
    case nameRequired
    case privateKeyRequired
    case privateKeyInvalid
    case addressInvalid
    case listenPortInvalid
    case MTUInvalid

    case publicKeyRequired
    case publicKeyInvalid
    case preSharedKeyInvalid
    case allowedIPsInvalid
    case endpointInvalid
    case persistentKeepAliveInvalid

    case publicKeyDuplicated
}
