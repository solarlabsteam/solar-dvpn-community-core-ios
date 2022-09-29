//
//  SOLARAPIProvider.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import Alamofire

// MARK: - Codable implementation

public extension InnerError {
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case message = "message"
    }
}

protocol SOLARAPIProvider: AnyObject {
    func getResponseHandler<T>(mapsInnerErrors: Bool, completion: @escaping (Result<T, NetworkError>) -> Void)
    -> ((AFDataResponse<T>) -> Void)
    
    func getResponseWithNilDataHandler(completion: @escaping (Result<Void, NetworkError>) -> Void)
    -> ((AFDataResponse<Data?>) -> Void)
}

extension SOLARAPIProvider {
    static func mapError<T>(mapsInnerErrors: Bool, error: AFError, response: AFDataResponse<T>) -> NetworkError {
        if mapsInnerErrors, let data = response.data {
            if let innerErrors = try? JSONDecoder().decode(InnerErrors.self, from: data),
               let firstError = innerErrors.errors.first {
                return .init(code: firstError.code, message: firstError.message)
            }
            
            if let innerError = try? JSONDecoder().decode(SingleInnerError.self, from: data).error {
                return .init(code: innerError.code, message: innerError.message)
            }
        }
        
        if let code = response.response?.statusCode {
            return .init(code: code, message: error.localizedDescription)
        }
        
        if let underlyingError = error.underlyingError as? URLError {
            return .init(code: underlyingError.errorCode, message: underlyingError.localizedDescription)
        }
        
        return .init(code: error.responseCode ?? 0, message: error.localizedDescription)
    }
    
    func getResponseHandler<T>(mapsInnerErrors: Bool = false, completion: @escaping (Result<T, NetworkError>) -> Void)
    -> ((AFDataResponse<T>) -> Void) {
        return { (response: AFDataResponse<T>) in
            let mapped = response.result
                .mapError { Self.mapError(mapsInnerErrors: mapsInnerErrors, error: $0, response: response) }
            completion(mapped)
        }
    }
    
    func getResponseWithNilDataHandler(completion: @escaping (Result<Void, NetworkError>) -> Void)
    -> ((AFDataResponse<Data?>) -> Void) {
        return { [unowned self] (response: AFDataResponse<Data?>) in
            let mapped = response.map { _ in }
            let handler = self.getResponseHandler(completion: completion)
            handler(mapped)
        }
    }
}
