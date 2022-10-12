//
//  StoreProduct.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 11.10.2022.
//

import Foundation
import RevenueCat

struct StoreProduct {
    let price: Decimal
    let currency: String
}

extension StoreProduct {
    init(from model: RevenueCat.StoreProduct) {
        self.price = model.price
        self.currency = model.priceFormatter?.currencySymbol ?? "$"
    }
}

extension StoreProduct: Codable {}
