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
    
    init(address: String, balance: Int, currency: String) {
        self.address = address
        self.balance = balance
        self.currency = currency
    }
}
