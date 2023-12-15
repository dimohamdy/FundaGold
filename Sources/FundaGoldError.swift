//
//  MyError.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 03/10/2023.
//

import Foundation

// Define custom errors
enum FundaGoldError: Error {
    case invalidURL
    case requestFailed
    case jsonParsingFailed
}
