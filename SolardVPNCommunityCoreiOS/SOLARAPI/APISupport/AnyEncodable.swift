//
//  AnyEncodable.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 27.09.2022.
//

import Foundation

struct AnyEncodable: Encodable {
    private let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}
