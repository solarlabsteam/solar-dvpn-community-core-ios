//
//  PurchasesModelError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 12.10.2022.
//

import Foundation

enum PurchasesModelError: LocalizedError {
    case purchaseCancelled
    
    var errorDescription: String? {
        switch self {
        case .purchaseCancelled:
            return "Purchase was canceled."
        }
    }
}
