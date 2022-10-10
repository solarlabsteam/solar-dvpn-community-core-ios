//
//  Error+Ext.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 10.10.2022.
//

import Foundation
import Vapor
import GRPC
import SOLARAPI

extension Error {
    var innerError: InnerError? {
        if let grpc = self as? (any GRPCErrorProtocol) {
            let status = grpc.makeGRPCStatus()
            
            return .init(code: status.code.rawValue, message: status.message ?? "unknown_error")
        }
        
        if let networkError = self as? NetworkError {
            return .init(code: networkError.code, message: networkError.message ?? "unknown_error")
        }
        
        return nil
    }
    
    func encodedError(status: UInt = 500) -> Abort {
        guard let innerError = self.innerError else {
            return .init(.internalServerError, reason: self.localizedDescription)
        }
        guard let reason = innerError.toData()?.string else {
            return .init(.internalServerError)
        }
        return .init(.custom(code: status, reasonPhrase: reason))
    }
}
