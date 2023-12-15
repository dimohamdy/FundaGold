//
//  TelegramResponse.swift
//  FundaTelegram
//
//  Created by Dimo Abdelaziz on 04/10/2023.
//

import Foundation

struct TelegramResponse<T: Decodable>: Decodable {
    let ok: Bool
    let result: T?
    let description: String?
}

struct TelegramMessage: Decodable {
    let update_id: Int
    let message: TelegramMessageInfo?

    enum CodingKeys: String, CodingKey {
        case updateId = "update_id"
        case message
        case myChatMember = "my_chat_member"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        update_id = try container.decode(Int.self, forKey: .updateId)
        if container.contains(.message) {
            message = try container.decode(TelegramMessageInfo.self, forKey: .message)
        } else {
            message = nil
        }
    }
}

struct TelegramMessageInfo: Decodable {
    let message_id: Int // This is the correct field name for message ID
    let chat: TelegramChat
    let text: String
}

struct TelegramChat: Decodable {
    let id: Int
}
