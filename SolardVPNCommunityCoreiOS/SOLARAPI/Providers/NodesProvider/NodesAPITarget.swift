//
//  NodesAPITarget.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import Alamofire

enum NodesAPITarget {
    case getNodes(GetNodesRequest)
}

extension NodesAPITarget: APITarget {
    var method: HTTPMethod {
        switch self {
        case .getNodes:
            return .get
        }
    }

    var path: String {
        switch self {
        case .getNodes:
            return "dvpn/getNodes"
        }
    }

    var parameters: Parameters {
        switch self {
        case let .getNodes(request):
            return .requestParameters(parameters: request.dictionary ?? [:], encoding: URLEncoding.default)
        }
    }
}
