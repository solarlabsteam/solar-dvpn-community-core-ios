//
//  PackageType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 11.10.2022.
//

import Foundation

enum PackageType: Int {
    case unknown = -2
    case custom
    case lifetime
    case annual
    case sixMonth
    case threeMonth
    case twoMonth
    case monthly
    case weekly
}

extension PackageType: Codable {}
