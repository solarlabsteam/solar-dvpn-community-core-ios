//
//  NodesByAddressPostBody.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 30.09.2022.
//

import Vapor

struct NodesByAddressPostBody: Content {
    let blockchain_addresses: [String]
    let page: Int?
}
