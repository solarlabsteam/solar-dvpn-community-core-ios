//
//  StoresWallet.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

protocol StoresWallet {
    func set(wallet: String)
    var walletAddress: String { get }
}
