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
    case postNodesByAddress(PostNodesByAddressRequest)
    case getCountries
}

extension NodesAPITarget: APITarget {
    var method: HTTPMethod {
        switch self {
        case .getNodes:
            return .get
        case .postNodesByAddress:
            return .post
        case .getCountries:
            return .get
        }
    }

    var path: String {
        switch self {
        case .getNodes:
            return "dvpn/getNodes"
        case .postNodesByAddress:
            return "dvpn/getNodesByAddress"
        case .getCountries:
            return "dvpn/getCountries"
        }
    }

    var parameters: Parameters {
        switch self {
        case let .getNodes(request):
            return .requestParameters(parameters: request.dictionary ?? [:], encoding: URLEncoding.default)
        case let .postNodesByAddress(request):
            return .requestJSONEncodable(request)
        case .getCountries:
            return .requestPlain
        }
    }
}
