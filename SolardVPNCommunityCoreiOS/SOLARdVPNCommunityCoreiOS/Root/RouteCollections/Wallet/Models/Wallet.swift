//
//  Wallet.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 04.10.2022.
//

import Foundation

struct Wallet: Codable {
    let address: String
    let balance: Int
    let currency: String
}
