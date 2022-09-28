//
//  APITarget.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import Alamofire

protocol APITarget {
    var method: Alamofire.HTTPMethod { get }
    var path: String { get }
    var parameters: Parameters { get }
}

enum Parameters {
    case requestPlain
    case requestJSONEncodable(Encodable)
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)
}
