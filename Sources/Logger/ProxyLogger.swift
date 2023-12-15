//
//  ProxyLogger.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 12/03/2023.
//

import Foundation
import Logging

class ProxyLogger: LoggerProtocol {

    let logger: Logger

    init(category: String) {
        self.logger = Logger(label: category)
    }

    func log(_ message: String, level: LogLevel) {

        // Map the LogLevel to the corresponding OSLogType
        let logType: Logger.Level
        switch level {
        case .debug:
            logType = .debug
        case .info:
            logType = .info
        case .warning:
            logType = .trace
        case .error:
            logType = .error
        }

        #if DEBUG
            logger.log(level: logType, "ProxyLogger: \(message)")
        #endif
    }
}
