//
//  PacketTunnelProvider.swift
//  WireGuardNetworkExtension
//
//  Created by Lika Vorobeva on 28.09.2022.
//

import NetworkExtension
import WireGuardKit

final class PacketTunnelProvider: NEPacketTunnelProvider {
    private lazy var adapter: WireGuardAdapter = {
        return WireGuardAdapter(with: self) { logLevel, message in
            log.debug(message)
        }
    }()

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        log.debug("QNEPacketTunnel.Provider: init")
        let activationAttemptId = options?["activationAttemptId"] as? String

        log.debug("Starting tunnel from the " + (activationAttemptId == nil ? "OS directly" : "app"))

        guard let tunnelProviderProtocol = self.protocolConfiguration as? NETunnelProviderProtocol,
              let tunnelConfiguration = tunnelProviderProtocol.asTunnelConfiguration() else {
            log.error(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            completionHandler(PacketTunnelProviderError.savedProtocolConfigurationIsInvalid)
            return
        }
        adapter.start(tunnelConfiguration: tunnelConfiguration) { adapterError in
            guard let adapterError = adapterError else {
                let interfaceName = self.adapter.interfaceName ?? "unknown"

                log.debug("Tunnel interface is \(interfaceName)")

                completionHandler(nil)
                return
            }

            switch adapterError {
            case .cannotLocateTunnelFileDescriptor:
                log.error("Starting tunnel failed: could not determine file descriptor")
                completionHandler(PacketTunnelProviderError.couldNotDetermineFileDescriptor)

            case .dnsResolution(let dnsErrors):
                let hostnamesWithDnsResolutionFailure = dnsErrors.map { $0.address }
                    .joined(separator: ", ")
                log.error("DNS resolution failed for the following hostnames: \(hostnamesWithDnsResolutionFailure)")
                completionHandler(PacketTunnelProviderError.dnsResolutionFailure)

            case .setNetworkSettings(let error):
                log.error("Starting tunnel failed with setTunnelNetworkSettings returning \(error.localizedDescription)")
                completionHandler(PacketTunnelProviderError.couldNotSetNetworkSettings)

            case .startWireGuardBackend(let errorCode):
                log.error("Starting tunnel failed with wgTurnOn returning \(errorCode)")
                completionHandler(PacketTunnelProviderError.couldNotStartBackend)

            case .invalidState:
                fatalError()
            }
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        log.debug("Stopping tunnel")

        adapter.stop { error in
            if let error = error {
                log.error("Failed to stop WireGuard adapter: \(error.localizedDescription)")
            }
            completionHandler()
        }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
        guard let completionHandler = completionHandler else { return }

        if messageData.count == 1 && messageData[0] == 0 {
            adapter.getRuntimeConfiguration { settings in
                var data: Data?
                if let settings = settings {
                    data = settings.data(using: .utf8)!
                }
                completionHandler(data)
            }
            return
        }
        completionHandler(nil)
    }
}
