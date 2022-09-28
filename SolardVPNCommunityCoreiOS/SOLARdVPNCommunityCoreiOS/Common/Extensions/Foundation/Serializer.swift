//
//  Serializer.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

enum Serializer {
    static func toData<T: Encodable>(from object: T) -> Data? {
        if let data = try? JSONEncoder().encode(object) {
            return data
        }
        if let dataConvertible = object as? DataConvertible, let data = dataConvertible.data {
            return data
        }
        return nil
    }

    static func fromData<T: Decodable>(_ data: Data, withType type: T.Type) -> T? {
        if let object = try? JSONDecoder().decode(type.self, from: data) {
            return object
        }
        if let Type = T.self as? DataConvertible.Type, let object = Type.init(data: data) as? T {
            return object
        }
        return nil
    }
}

// MARK: - DataConvertible

protocol DataConvertible {
    init?(data: Data)
    var data: Data? { get }
}

extension DataConvertible {
    init?(data: Data) {
        guard data.count == MemoryLayout<Self>.size else { return nil }
        self = data.withUnsafeBytes { $0.load(as: Self.self) }
    }

    var data: Data? {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

// MARK: - DataConvertible implementation

extension Int: DataConvertible { }
extension Float: DataConvertible { }
extension Double: DataConvertible { }
extension Bool: DataConvertible { }
extension String: DataConvertible {
    init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }

    var data: Data? {
        return data(using: .utf8)
    }
}

extension Encodable {
    func toData() -> Data? {
        return Serializer.toData(from: self)
    }
}
