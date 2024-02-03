//
//  Action.swift
//
//
//  Created by Dimo Abdelaziz on 22/01/2024.
//

import Foundation

enum Action {    
    case clear(chatID: String)
    case search(FundaTask)
    case replay(chatID: String, message: String)
}
