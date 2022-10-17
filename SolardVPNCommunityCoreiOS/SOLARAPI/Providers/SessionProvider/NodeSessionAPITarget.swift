//
//  NodeSessionAPITarget.swift
//  SOLARAPI
//
//  Created by Lika Vorobeva on 26.09.2022.
//

import Foundation
import Alamofire

enum NodeSessionAPITarget {
    case createClient(address: String, id: String, request: StartSessionRequest)
}

extension NodeSessionAPITarget: APITarget {
    var method: HTTPMethod {
        switch self {
        case .createClient:
            return .post
        }
    }

    var path: String {
        switch self {
        case let .createClient(address, id, _):
            return "accounts/\(address)/sessions/\(id)"
        }
    }

    var parameters: Parameters {
        switch self {
        case let .createClient(_, _, data):
            return .requestJSONEncodable(data)
        }
    }
}
