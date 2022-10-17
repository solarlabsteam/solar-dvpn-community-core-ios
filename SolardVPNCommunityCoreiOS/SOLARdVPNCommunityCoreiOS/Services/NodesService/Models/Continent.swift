//
//  Continent.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

enum Continent: String, CaseIterable {
    case africa = "AF"
    case southAmerica = "SA"
    case northAmerica = "NA"
    case asia = "AS"
    case europe = "EU"
    case oceania = "OC"
    case antarctica = "AN"
}

extension Continent {
    var code: String? {
        self.rawValue
    }
}

extension Continent: Codable {}
