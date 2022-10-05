//
//  ConnectionModelError.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation

enum ConnectionModelError: Error {
    case signatureGenerationFailed
    case nodeIsOffline
    case balanceUpdateFailed
    case noSelectedNode
    case noSubscription
    case noQuotaLeft
}
