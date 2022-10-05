//
//  PostMnemonicResponse.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 05.10.2022.
//

import Foundation

struct PostMnemonicResponse: Codable {
    let wallet: Wallet
    let mnemonic: String
}
