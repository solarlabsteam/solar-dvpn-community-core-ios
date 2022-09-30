//
//  NetworkError.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

public struct NetworkError: Error {
    public let code: Int
    public let message: String?
    
    public var localization: String? {
        return message
    }
    
    public var badRequest: Bool {
        code == 400
    }
    
    public var unauthorized: Bool {
        401...402 ~= code
    }

    public var accessDenied: Bool {
        code == 403
    }
    
    public var notFound: Bool {
        code == 404
    }
    
    public var isServerError: Bool {
        500...511 ~= code
    }
}

struct InnerErrors: Codable {
    let errors: [InnerError]
}

struct SingleInnerError: Codable {
    let error: InnerError
}

public struct InnerError: Codable {
    let code: Int
    let message: String
    
    public init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
}
