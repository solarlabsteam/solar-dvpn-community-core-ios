//
//  Config.swift
//  SOLARdVPNCommunityCoreiOS
//
//  Created by Lika Vorobeva on 28.09.2022.
//


import UIKit
import SwiftyBeaver

let log = SwiftyBeaver.self

public struct Config {
    static func setup() {
        LogsConfig.setupConsole()
    }
}

struct LogsConfig {
    static func setupConsole() {
        let console = ConsoleDestination()
        setup(destination: console)
        log.addDestination(console)
    }
    
    private static func setup(destination: BaseDestination) {
        destination.levelColor.verbose = "📓 "
        destination.levelColor.debug = "📗 "
        destination.levelColor.info = "📘 "
        destination.levelColor.warning = "📒 "
        destination.levelColor.error = "📕 "
        #if DEBUG
        destination.minLevel = .verbose
        #else
        destination.minLevel = .info
        #endif
    }
}
