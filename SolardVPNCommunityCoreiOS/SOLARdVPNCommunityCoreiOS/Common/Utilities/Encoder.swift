//
//  Encoder.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 03.10.2022.
//

import Foundation

enum EncoderError: LocalizedError {
    case failToEncode
    
    var errorDescription: String? {
        switch self {
        case .failToEncode:
            return "Fail to encode"
        }
    }
}

enum Encoder {
    static func encode(
        model: Codable,
        continuation: CheckedContinuation<String, Error>
    ) {
        do {
            let result = try JSONEncoder().encode(model)
            let string = String(decoding: result, as: UTF8.self)
            continuation.resume(returning: string)
        } catch {
            continuation.resume(throwing: EncoderError.failToEncode)
        }
    }
}
