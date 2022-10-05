//
//  ConnectionModelType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 30.09.2022.
//

import Foundation

protocol ConnectionModelDelegate: AnyObject {
    func show(error: SingleInnerError)
    func show(warning: SingleInnerError)
    
    func set(isLoading: Bool)
}

protocol ConnectionModelType: AnyObject {
    func connect(to node: String) -> Bool 
}
