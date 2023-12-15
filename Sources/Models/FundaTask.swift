//
//  FundaTask.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 07/10/2023.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let searchStrategies: [SearchStrategy] = [FundaSearchStrategy(), ParariusSearchStrategy(), WonenbijbouwinvestStrategy(), VestedaStrategy(), IkwilhurenStrategy()]

class FundaTask {
    let chatID: String
    private var propertyLinks: Set<String> = Set([])
    private var linkStorage: LinkStorageRepository

    var searchConfig: SearchConfig
    let logger: LoggerProtocol

    init(chatID: String, searchConfig: SearchConfig, linkStorage: LinkStorageRepository = UserDefaultsLinkStorage(), logger: LoggerProtocol) {
        self.chatID = chatID
        self.searchConfig = searchConfig
        self.linkStorage = linkStorage
        self.propertyLinks = Set(linkStorage.loadLinks(forChatID: chatID))
        self.logger = logger
    }

    func contains(link: String) -> Bool {
        return propertyLinks.contains(link)
    }

    func save(link: String) {
        linkStorage.saveLink(chatID: chatID, link: link)
    }

    func run() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 5.0...10.0) * 60) { [weak self] in
            guard let self else {
                return
            }
            let date = String(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))
            print("⏰ \(date) _ 💬 \(self.chatID))")
            searchStrategies.forEach { strategy in

                Task {

                    do {

                        // Execute the search using the selected strategy
                        try await strategy.search(fundaTask: self)

                    } catch {
                        self.logger.log("Error during search: \(error)", level: .error)
                    }

                }
            }
        }
    }

}
