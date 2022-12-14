//
//  NodesProvider.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation
import Alamofire

public final class NodesProvider: SOLARAPIProvider {
    public struct Configuration {
        public let baseURL: URL

        public init(baseURL: URL) {
            self.baseURL = baseURL
        }
    }

    private let configuration: Configuration

    public init(configuration: Configuration) {
        self.configuration = configuration
    }
}

extension NodesProvider: NodesProviderType {
    public func getNodes(
        _ getNodesRequest: GetNodesRequest,
        completion: @escaping (Result<PageResponse<Node>, NetworkError>) -> Void
    ) {
        AF
            .request(request(for: .getNodes(getNodesRequest)))
            .validate()
            .responseDecodable(completionHandler: getResponseHandler(completion: completion))
    }
    
    public func postNodesByAddress(
        _ postNodesRequest: PostNodesByAddressRequest,
        completion: @escaping (Result<PageResponse<Node>, NetworkError>) -> Void
    ) {
        AF
            .request(request(for: .postNodesByAddress(postNodesRequest)))
            .validate()
            .responseDecodable(completionHandler: getResponseHandler(completion: completion))
    }
    
    public func getCountries(completion: @escaping (Result<[Country], NetworkError>) -> Void) {
        AF
            .request(request(for: .getCountries))
            .validate()
            .responseDecodable(completionHandler: getResponseHandler(completion: completion))
    }
}

private extension NodesProvider {
    func request(for target: NodesAPITarget) -> APIRequest {
        return .init(baseURL: configuration.baseURL, target: target)
    }
}
