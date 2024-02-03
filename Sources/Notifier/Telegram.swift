//
//  Telegram.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 03/10/2023.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let botToken = ProcessInfo.processInfo.environment["BOT_TOKEN"] ?? "defaultToken"

class Telegram: Notifier {


    // Define the Telegram API endpoint for long polling updates
    private let apiUrl = "https://api.telegram.org/bot\(botToken)/getUpdates"
    private var lastUpdateID: Int?

    let logger: LoggerProtocol
    let executor: Executor
    init(logger: LoggerProtocol = ProxyLogger(category: "Telegram")) {
        self.logger = logger
        logger.log("BOT_TOKEN \(ProcessInfo.processInfo.environment["BOT_TOKEN"])", level: .debug)
        logger.log("apiUrl \(apiUrl)", level: .debug)
        self.executor = Executor(logger:  ProxyLogger(category: "Executor"),
                                 storageRepository: UserDefaultsLinkStorage())
        self.executor.telegram = self
    }

    func pollMessages() async throws {
        do {
            guard let url = createURL() else { return }
            let (data, _) = try await fetchData(url: url)
            let messages = try parseMessages(from: data)
            guard !messages.isEmpty else {
                try await sleepAndRetry()
                return
            }

            for message in  messages {
                let actions = handleMessage(message)
                await executor.run(actions: actions)
            }

            try await sleepAndRetry()

        } catch {
            logger.log(error.localizedDescription, level: .error)
            try await sleepAndRetry()
        }
    }


    func replay(chatID: String, message: String) async {
        // Handle the incoming message and generate a response
        do {
            try await notifyUser(chatID: chatID, message: message)
        } catch {
            logger.log(error.localizedDescription, level: .error)
        }
    }

    private func createURL() -> URL? {
        guard var urlComponents = URLComponents(string: apiUrl) else {
            logger.log("Invalid API URL", level: .error)
            return nil
        }

        if let lastID = lastUpdateID {
            urlComponents.queryItems = [URLQueryItem(name: "offset", value: String(lastID + 1))]
        }

        return urlComponents.url
    }

    private func fetchData(url: URL) async throws -> (Data, URLResponse) {
        let request = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        return try await session.data(with: request)
    }

    private func parseMessages(from data: Data) throws -> [TelegramMessage] {
        let str = String(decoding: data, as: UTF8.self)
        logger.log("JSON \(str)", level: .info)

        let decoder = JSONDecoder()
        let response = try decoder.decode(TelegramResponse<[TelegramMessage]>.self, from: data)
        return response.ok ? response.result ?? [] : []
    }

    private func handleMessage(_ message: TelegramMessage) -> [Action] {
        guard let chatID = message.message?.chat.id, let text = message.message?.text else { return [] }
        let updateID = message.update_id
        lastUpdateID = updateID

        if text.lowercased() == "clear"  {
            return [.clear(chatID: "\(chatID)"),
                    .replay(chatID: "\(chatID)", message: "Clear Done ✅")]
        }

        guard let config = try? SearchConfig.loadParameters(configString: text) else {
            return [.replay(chatID: "\(chatID)", message: "Wrong Config, Please try again, if you need a help message @dimohamdy")]
        }


        let fundaTask = FundaTask(chatID: "\(chatID)", searchConfig: config, logger: ProxyLogger(category: "FundaTask"))
        fundaTask.searchConfig = config
        return [.replay(chatID: fundaTask.chatID, message: "🔔 We'll keep you posted on the latest property listings."),
                .search(fundaTask)]
    }

    func sleepAndRetry() async throws {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Sleep for 2 second
        try await pollMessages()
    }

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
