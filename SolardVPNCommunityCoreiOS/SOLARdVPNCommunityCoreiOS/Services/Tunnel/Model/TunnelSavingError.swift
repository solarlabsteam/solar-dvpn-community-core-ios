//
//  SavingError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

enum TunnelSavingError: String, LocalizedError {
    case nameRequired = "name_equired"
    case privateKeyRequired = "private_key_required"
    case privateKeyInvalid = "private_key_invalid"
    case addressInvalid = "address_invalid"
    case listenPortInvalid = "listen_port_invalid"
    case MTUInvalid = "mtu_invalid"

    case publicKeyRequired = "public_key_required"
    case publicKeyInvalid = "public_key_invalid"
    case preSharedKeyInvalid = "pre_shared_key_invalid"
    case allowedIPsInvalid = "allowed_ips_invalid"
    case endpointInvalid = "endpoint_invalid"
    case persistentKeepAliveInvalid = "persistent_keep_alive_invalid"

    case publicKeyDuplicated = "public_key_duplicated"
    
    var errorDescription: String? {
        self.rawValue
    }
}
