//
//  NodeSessionProviderType.swift
//  SOLARAPI
//
//  Created by Lika Vorobeva on 26.09.2022.
//

import Foundation
import Alamofire

public protocol NodeSessionProviderType {
    func createClient(
        remoteURL: URL,
        address: String,
        id: String,
        request: StartSessionRequest,
        completion: @escaping (Result<StartSessionResponse, NetworkError>) -> Void
    )
}
