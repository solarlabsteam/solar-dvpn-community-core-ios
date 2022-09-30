//
//  NodesProviderType.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import Alamofire

public protocol NodesProviderType {
    func getNodes(
        _ getNodesRequest: GetNodesRequest,
        completion: @escaping (Result<PageResponse<Node>, NetworkError>) -> Void
    )
}
