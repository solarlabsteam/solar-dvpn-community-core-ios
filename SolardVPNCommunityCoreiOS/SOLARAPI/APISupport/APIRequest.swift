//
//  APIRequest.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Foundation
import Alamofire

struct APIRequest: URLRequestConvertible {
    let baseURL: URL
    let target: APITarget
}

extension APIRequest {
    func asURLRequest() throws -> URLRequest {
        var request = try URLRequest(url: baseURL.appendingPathComponent(target.path), method: target.method)
        
        switch target.parameters {
        case .requestPlain:
            break
        case let .requestJSONEncodable(encodable):
            let encodable = AnyEncodable(encodable)
            request.httpBody = try JSONEncoder().encode(encodable)
            
            let contentTypeHeaderName = "Content-Type"
            if request.value(forHTTPHeaderField: contentTypeHeaderName) == nil {
                request.setValue("application/json", forHTTPHeaderField: contentTypeHeaderName)
            }
        case let .requestParameters(parameters, encoding):
            request = try encoding.encode(request, with: parameters)
        }
        
        return request
    }
}
