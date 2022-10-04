//
//  ConnectionModelType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation

protocol ConnectionModelDelegate: AnyObject {
    func show(error: Error)
    func show(warning: Error)
    
    func set(isLoading: Bool)
}

protocol ConnectionModelType: AnyObject {
    func connect()
    func refreshNode()
}

protocol NodeModelDelegate: AnyObject {
    func openPlans(node: Node, resubscribe: Bool)
    func suggestUnsubscribe(from node: Node)
}
