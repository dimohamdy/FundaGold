//
//  Executor.swift
//  
//
//  Created by Dimo Abdelaziz on 27/01/2024.
//

import Foundation


class Executor {
    let storageRepository: LinkStorageRepository
    let logger: LoggerProtocol
    weak var telegram: Telegram?

    init(logger: LoggerProtocol, storageRepository: LinkStorageRepository) {
        self.logger = logger
        self.storageRepository = storageRepository
    }

    func run(actions: [Action]) async {
        for action in actions {
            await runCommand(action: action)
        }
    }

    private func runCommand(action: Action) async {
        switch action {
        case .clear(let chatID):
            storageRepository.clearData(forChatID: "\(chatID)")
            searchTasks[chatID]?.clearPropertyLinks()

        case .search(let fundaTask):
            let chatID = fundaTask.chatID
            searchTasks[chatID] = fundaTask

        case .replay(let chatID, let message):
            await telegram?.replay(chatID: chatID, message: message)

        }
    }
}
