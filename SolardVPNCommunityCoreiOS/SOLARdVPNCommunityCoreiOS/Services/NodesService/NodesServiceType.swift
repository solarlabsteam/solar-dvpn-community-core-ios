//
//  NodesServiceType.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import SOLARAPI

protocol NodesServiceType {
    var nodes: [Node] { get }
    func loadNodes(
        continent: Continent?,
        countryCode: String?,
        minPrice: Int?,
        maxPrice: Int?,
        orderBy: OrderType?,
        query: String?,
        page: Int?,
        completion: @escaping (Result<PageResponse<Node>, Error>) -> Void
    )
    func getNode(by: String, completion: @escaping (Result<Node, Error>) -> Void)
}
