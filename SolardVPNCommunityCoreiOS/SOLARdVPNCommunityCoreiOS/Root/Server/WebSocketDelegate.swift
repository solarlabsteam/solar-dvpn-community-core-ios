//
//  WebSocketDelegate.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 04.10.2022.
//

import Foundation

protocol WebSocketDelegate: AnyObject {
    func send(event: String)
}
