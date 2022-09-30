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
        continentCode: String?,
        countryCode: String?,
        minPrice: Int?,
        maxPrice: Int?,
        orderBy: OrderType?,
        query: String?,
        page: Int?
    ) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            nodesProvider.getNodes(
                .init(
                    status: .active,
                    continentCode: continentCode,
                    countryCode: countryCode,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    orderBy: orderBy,
                    query: query,
                    page: page
                )
            ) { result in
                switch result {
                case let .success(response):
                    Encoder.encode(model: response, continuation: continuation)
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: error.code), reason: error.localizedDescription))
                }
            }
        })
    }
    
    func getNodes(
        by addresses: [String],
        page: Int?
    ) async throws -> String {
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<String, Error>) in
            nodesProvider.postNodesByAddress(.init(addresses: addresses, page: page)) { result in
                switch result {
                case let .success(response):
                    Encoder.encode(model: response, continuation: continuation)
                case let .failure(error):
                    continuation.resume(throwing: Abort(.init(statusCode: error.code), reason: error.localizedDescription))
                }
            }
        })
    }
}
