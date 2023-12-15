//
//  Notifier.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation

protocol Notifier {
    func notifyUser(chatID: String, message: String) async throws
}
