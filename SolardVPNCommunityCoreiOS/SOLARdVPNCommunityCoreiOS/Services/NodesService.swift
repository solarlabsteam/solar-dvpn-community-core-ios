//
//  NodesService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import SOLARAPI
import Vapor

final class NodesService {
    private let nodesProvider: NodesProviderType
    
    init(
        nodesProvider: NodesProviderType
    ) {
        self.nodesProvider = nodesProvider
    }
}

// MARK: - NodesServiceType

extension NodesService: NodesServiceType {
    func loadNodes(
        continent: Continent?,
        countryCode: String?,
        minPrice: Int?,
        maxPrice: Int?,
        orderBy: OrderType?,
        query: String?,
        page: Int?
    ) async throws -> String {
        try await withCheckedThrowingContinuation({  (continuation: CheckedContinuation<String, Error>) in
            nodesProvider.getNodes(
                .init(
                    status: .active,
                    continentCode: continent?.code,
                    countryCode: countryCode,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    orderBy: orderBy,
                    query: query,
                    page: page
                )
            ) { result in
                switch result {
                case let .success(success):
                    let result = try! JSONEncoder().encode(success)
                    let string = String(decoding: result, as: UTF8.self)
                    continuation.resume(returning: string)
                    
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: error.code), reason: error.localizedDescription))
                }
            }
        })
    }
}
