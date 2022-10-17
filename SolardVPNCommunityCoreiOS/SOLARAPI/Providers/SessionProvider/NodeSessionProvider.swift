//
//  NodeSessionProvider.swift
//  SOLARAPI
//
//  Created by Lika Vorobeva on 26.09.2022.
//

import Foundation
import Alamofire

public final class NodeSessionProvider: SOLARAPIProvider {
    public init() {}
}

// MARK: - StealthProviderType implementation

extension NodeSessionProvider: NodeSessionProviderType {
    public func createClient(
        remoteURL: URL,
        address: String,
        id: String,
        request: StartSessionRequest,
        completion: @escaping (Result<StartSessionResponse, NetworkError>) -> Void
    ) {
        let apiRequest = APIRequest(
            baseURL: remoteURL,
            target: NodeSessionAPITarget.createClient(address: address, id: id, request: request)
        )
        
        AF.request(apiRequest)
            .validate()
            .responseDecodable(completionHandler: getResponseHandler(mapsInnerErrors: true, completion: completion))
    }
}
