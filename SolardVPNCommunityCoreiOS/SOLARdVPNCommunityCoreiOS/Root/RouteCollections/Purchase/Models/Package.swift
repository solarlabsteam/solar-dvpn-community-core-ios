//
//  Package.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 11.10.2022.
//

import Foundation
import RevenueCat

struct Package {
    let identifier: String
    let packageType: PackageType
    let storeProduct: StoreProduct
    let offeringIdentifier: String
    let localizedPriceString: String
    let localizedIntroductoryPriceString: String?
}

extension Package {
    init?(from optionalModel: RevenueCat.Package?) {
        guard let model = optionalModel else {
            return nil
        }
        
        self.init(from: model)
    }
    
    init(from model: RevenueCat.Package) {
        self.identifier = model.identifier
        self.packageType = PackageType.init(rawValue: model.packageType.rawValue) ?? .unknown
        self.storeProduct = StoreProduct.init(from: model.storeProduct)
        self.offeringIdentifier = model.offeringIdentifier
        self.localizedPriceString = model.localizedPriceString
        self.localizedIntroductoryPriceString = model.localizedIntroductoryPriceString
    }
}

extension Package: Codable {}
