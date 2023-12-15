//
//  LoggerProtocol.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 12/03/2023.
//

import Foundation

protocol LoggerProtocol {
    func log(_ message: String, level: LogLevel)
}
