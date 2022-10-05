//
//  Node.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 03.10.2022.
//

import Foundation
import SOLARAPI

typealias Node = SOLARAPI.Node

extension Node {
    var truncatedAddress: String {
        "sent..." + String(address).suffix(8)
    }
}
