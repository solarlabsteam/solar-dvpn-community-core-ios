//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import Foundation

enum ConfigurationParserState {
    case inInterfaceSection
    case inPeerSection
    case notInASection
}

enum ConfigurationParseError: LocalizedError {
    case invalidLine(String.SubSequence)
    case noInterface
    case multipleInterfaces
    case interfaceHasNoPrivateKey
    case interfaceHasInvalidPrivateKey(String)
    case interfaceHasInvalidListenPort(String)
    case interfaceHasInvalidAddress(String)
    case interfaceHasInvalidDNS(String)
    case interfaceHasInvalidMTU(String)
    case interfaceHasUnrecognizedKey(String)
    case peerHasNoPublicKey
    case peerHasInvalidPublicKey(String)
    case peerHasInvalidPreSharedKey(String)
    case peerHasInvalidAllowedIP(String)
    case peerHasInvalidEndpoint(String)
    case peerHasInvalidPersistentKeepAlive(String)
    case peerHasInvalidTransferBytes(String)
    case peerHasInvalidLastHandshakeTime(String)
    case peerHasUnrecognizedKey(String)
    case multiplePeersWithSamePublicKey
    case multipleEntriesForKey(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidLine, .noInterface, .multipleInterfaces, .interfaceHasNoPrivateKey, .interfaceHasInvalidPrivateKey,
                .interfaceHasInvalidListenPort, .interfaceHasInvalidAddress, .interfaceHasInvalidDNS,
                .interfaceHasInvalidMTU, .interfaceHasUnrecognizedKey:
            return "invalid_interface"
        default:
            return "invalid_peer"
        }
    }
}
