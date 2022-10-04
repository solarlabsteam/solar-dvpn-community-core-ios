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
    
    private var loadedCountries: [Country] = []
    private var _countriesInContinents: [Continent: [Country]] = [:]
    
    init(
        nodesProvider: NodesProviderType
    ) {
        self.nodesProvider = nodesProvider
        
        getCountries() { _ in }
    }
}

// MARK: - NodesServiceType

extension NodesService: NodesServiceType {
    
    // MARK: - Nodes
    
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
    
    // MARK: - Countries & Continents
    
    var nodesInContinentsCount: [Continent: Int] {
        _countriesInContinents.reduce([:]) { acc, entry in
            var tempAcc = acc
            tempAcc[entry.key] = entry.value.map { $0.nodesCount }.reduce(0) { $0 + $1 }
            return tempAcc
        }
    }
    
    var countriesInContinents: [Continent: [Country]] {
        _countriesInContinents
    }
    
    func getCountries(completion: @escaping (Result<[Country], Error>) -> Void) {
        nodesProvider.getCountries() { [weak self] result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case let .success(countries):
                self?.loadedCountries = countries
                self?.countNodesInContinentsCount()
                completion(.success(countries))
            }
        }
    }
}

// MARK: - Private

extension NodesService {
    private func countNodesInContinentsCount() {
        Continent.allCases.forEach {
            _countriesInContinents[$0] = []
        }
        
        loadedCountries
            .forEach { country in
                if let continent = ContinentDecoder().getContinent(for: country.code) {
                    _countriesInContinents[continent]?.append(country)
                }
            }
    }
}
