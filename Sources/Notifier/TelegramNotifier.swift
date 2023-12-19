//
//  TelegramNotifier.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 03/10/2023.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class TelegramNotifier: Notifier {

    // Send message function
    func notifyUser(chatID: String, message: String) async throws {
        let baseURL = "https://api.telegram.org/bot\(botToken)/sendMessage"

        // Construct the URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw FundaGoldError.invalidURL
        }

        let queryItems = [
            URLQueryItem(name: "chat_id", value: chatID),
            URLQueryItem(name: "text", value: message)
        ]

        urlComponents.queryItems = queryItems

        // Create the URLRequest
        guard let url = urlComponents.url else {
            throw FundaGoldError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Send the request
        let (_, _) = try await URLSession.shared.data(with: request)

    }
}
