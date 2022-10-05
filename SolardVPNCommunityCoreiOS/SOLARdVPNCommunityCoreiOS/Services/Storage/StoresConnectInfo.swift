//
//  StoresConnectInfo.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 03.10.2022.
//

import Foundation

protocol StoresConnectInfo {
    func set(lastSelectedNode: String?)
    func lastSelectedNode() -> String?
    
    func set(sessionId: Int?)
    func lastSessionId() -> Int?
}
