//
//  TunnelChanges.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

struct Changes {
    enum FieldChange: Equatable {
        case added
        case removed
        case modified(newValue: String)
    }

    var interfaceChanges: [TunnelInterfaceField: FieldChange]
    var peerChanges: [(peerIndex: Int, changes: [PeerField: FieldChange])]
    var peersRemovedIndices: [Int]
    var peersInsertedIndices: [Int]
}
