//
//  NodesService.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import SOLARAPI

final class NodesService {
    private let nodesProvider: NodesProviderType
    
    private var loadedNodes: [Node] = []
    
    init(
        nodesProvider: NodesProviderType
    ) {
        self.nodesProvider = nodesProvider
    }
}

// MARK: - NodesServiceType

extension NodesService: NodesServiceType {
    var nodes: [Node] {
        loadedNodes
    }
    
    /// Loads active nodes and saves them to local variable
    func loadNodes(
        continent: Continent?,
        countryCode: String?,
        minPrice: Int?,
        maxPrice: Int?,
        orderBy: OrderType?,
        query: String?,
        page: Int?,
        completion: @escaping (Result<PageResponse<Node>, Error>) -> Void
    ) {
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
        ) { [weak self] result in
            switch result {
            case .failure(let error):
                log.error(error)
                completion(.failure(NodesServiceError.failToLoadData))
            case .success(let response):
                completion(.success(response))
                self?.loadedNodes = response.data
            }
        }
    }
    
    func getNode(
        by address: String,
        completion: @escaping (Result<Node, Error>) -> Void
    ) {
        nodesProvider.postNodesByAddress(.init(addresses: [address], page: nil)) { result in
            switch result {
            case .failure(let error):
                log.error(error)
                completion(.failure(NodesServiceError.failToLoadData))
            case .success(let response):
                guard let node = response.data.first else {
                    completion(.failure(NodesServiceError.failToLoadData))
                    return
                }

                completion(.success(node))
            }
        }
    }
}
