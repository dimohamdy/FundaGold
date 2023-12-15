//
//  LinkStorage.swift
//  FundaGold
//
//  Created by BinaryBoy on 12/9/23.
//

import Foundation

protocol LinkStorageRepository {
    func saveLink(chatID: String, link: String)
    func loadLinks(forChatID chatID: String) -> [String]
}

class UserDefaultsLinkStorage: LinkStorageRepository {

    func saveLink(chatID: String, link: String) {
        let defaults = UserDefaults.standard
        var links = defaults.object(forKey: chatID) as? [String] ?? []
        links.append(link)
        defaults.set(links, forKey: chatID)
    }

    func loadLinks(forChatID chatID: String) -> [String] {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: chatID) as? [String] ?? []
    }
}
