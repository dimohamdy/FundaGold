import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


var searchTasks: [String: FundaTask] = [:]

class Main {

    private var timer: Timer!
    private let telegram: Telegram

    init(telegram: Telegram) {
        self.telegram = telegram
        self.timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 5.0...7.0) * 60, repeats: true) {  _ in

            searchTasks.values.forEach { task in
                task.run()
            }
        }
    }

    func start()  {
        Task {
            try await telegram.pollMessages()
        }
    }
}



let main =  Main(telegram: Telegram(logger: ProxyLogger(category: "Telegram")))

// Start listening for messages within the current RunLoop
main.start()

RunLoop.current.run()
