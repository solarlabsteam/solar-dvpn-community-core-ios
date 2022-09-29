//
//  NodeStatusType.swift
//  SOLARAPI
//
//  Created by Viktoriia Kostyleva on 28.09.2022.
//

import Foundation

public enum NodeStatusType: String {
    case active = "STATUS_ACTIVE"
    case inactive = "STATUS_INACTIVE"
}

extension NodeStatusType: Codable {}
