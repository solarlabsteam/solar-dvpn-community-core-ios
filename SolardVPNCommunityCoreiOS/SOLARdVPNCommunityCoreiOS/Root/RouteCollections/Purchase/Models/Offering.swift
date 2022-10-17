//
//  Offering.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 11.10.2022.
//

import Foundation
import RevenueCat

struct Offering {
    let identifier: String
    let serverDescription: String
    let availablePackages: [Package]
    let lifetime: Package?
    let annual: Package?
    let sixMonth: Package?
    let threeMonth: Package?
    let twoMonth: Package?
    let monthly: Package?
    let weekly: Package?
}

extension Offering {
    init(from model: RevenueCat.Offering) {
        self.identifier = model.identifier
        self.serverDescription = model.serverDescription
        self.availablePackages = model.availablePackages.map { Package(from: $0) }
        self.lifetime = Package(from: model.lifetime)
        self.annual = Package(from: model.annual)
        self.sixMonth = Package(from: model.sixMonth)
        self.threeMonth = Package(from: model.threeMonth)
        self.twoMonth = Package(from: model.twoMonth)
        self.monthly = Package(from: model.monthly)
        self.weekly = Package(from: model.weekly)
    }
}

extension Offering: Codable {}
