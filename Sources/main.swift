import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let botToken = ProcessInfo.processInfo.environment["BOT_TOKEN"] ?? "defaultToken"


class Main {

    private var searchTasks: [Int: FundaTask] = [:]

    private var timer: Timer!

    // Define the Telegram API endpoint for long polling updates
    private let apiUrl = "https://api.telegram.org/bot\(botToken)/getUpdates"
    private let notifier = TelegramNotifier()
    private var lastUpdateID: Int?

    let logger: LoggerProtocol
    let storageRepository: LinkStorageRepository

    init(logger: LoggerProtocol, storageRepository: LinkStorageRepository) {
        logger.log("BOT_TOKEN \(ProcessInfo.processInfo.environment["BOT_TOKEN"])", level: .debug)
        logger.log("apiUrl \(apiUrl)", level: .debug)

        self.logger = logger
        self.storageRepository = storageRepository
        self.timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 5.0...7.0) * 60, repeats: true) { [weak self] _ in

            self?.searchTasks.values.forEach { task in
                task.run()
            }
        }
    }

    func pollMessagesFromTelegram() async {
        do {
            guard let url = createURL() else { return }
            let (data, _) = try await fetchData(url: url)
            let messages = try parseMessages(from: data)
            guard !messages.isEmpty else {
                await sleepAndRetry()
                return
            }

            for message in messages {
                try await handleMessage(message)
            }
        } catch {
            logger.log(error.localizedDescription, level: .error)
            await sleepAndRetry()
        }
    }

    private func replay(chatID: String, message: String) async {
        // Handle the incoming message and generate a response
        do {
            try await notifier.notifyUser(chatID: chatID, message: message)
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

    private func handleMessage(_ message: TelegramMessage) async throws {
        guard let chatID = message.message?.chat.id, let text = message.message?.text else { return }
        let updateID = message.update_id
        lastUpdateID = updateID

        if Actions(rawValue: text.lowercased()) == .clear  {
            storageRepository.clearData(forChatID: "\(chatID)")
            searchTasks[chatID]?.clearPropertyLinks()
            await replay(chatID: "\(chatID)", message: "Clear Done ✅")
            await sleepAndRetry()
            return
        }

        guard let config = try? SearchConfig.loadParameters(configString: text) else {
            await replay(chatID: "\(chatID)", message: "Wrong Config, Please try again, if you need a help message @dimohamdy")
            await sleepAndRetry()
            return
        }

        let fundaTask = searchTasks[chatID] ?? FundaTask(chatID: "\(chatID)", searchConfig: config, logger: ProxyLogger(category: "FundaTask"))
        fundaTask.searchConfig = config
        await replay(chatID: fundaTask.chatID, message: "🔔 We'll keep you posted on the latest property listings.")
        searchTasks[chatID] = fundaTask
        await sleepAndRetry()
    }

    private func sleepAndRetry() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // Sleep for 2 second
        await pollMessagesFromTelegram()
    }

}

let main =  Main(logger: ProxyLogger(category: "Main"), storageRepository: UserDefaultsLinkStorage())


// Start listening for messages within the current RunLoop
Task {
    await main.pollMessagesFromTelegram()
}

RunLoop.current.run()
