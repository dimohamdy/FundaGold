//
//  SearchStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let telegram = TelegramNotifier()

protocol SearchStrategy {
    var logger: LoggerProtocol { get set }
    func search(fundaTask: FundaTask) async throws
}

extension SearchStrategy {

    // Function to get a random User-Agent
    func getRandomUserAgent() -> String {
        // Define an array of User-Agent strings
        let userAgents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.9999.99 Safari/537.36",
            "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko",
            "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:90.0) Gecko/20100101 Firefox/90.0",
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (Android 11; Mobile; rv:90.0) Gecko/90.0 Firefox/90.0",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0",
            "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:89.0) Gecko/20100101 Firefox/89.0",
            "Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1",
            "Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.9999.99 Mobile Safari/537.36"
        ]

        let randomIndex = Int.random(in: 0..<userAgents.count)
        return userAgents[randomIndex]
    }

    // Function to fetch HTML content from a URL
    func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        // Perform the URL request
        let (data, _) = try await URLSession.shared.data(with: request)

        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw FundaGoldError.invalidURL
        }

        return htmlString
    }

    // Function to parse JSON from a script element
    func parseJSON(from scriptData: String) throws -> [String: Any] {
        guard let jsonData = scriptData.data(using: .utf8),
              let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw FundaGoldError.jsonParsingFailed
        }
        return jsonObject
    }

    func sendLinks(fundaTask: FundaTask, propertyURLs: [String]) async {
        for url in propertyURLs {
            if !fundaTask.contains(link: url) {
                fundaTask.save(link: url)
                do {
                    try await telegram.notifyUser(chatID: fundaTask.chatID, message: url)
                } catch {
                    logger.log("Error sending to Telegram: \(error)", level: .error)
                }
            }
        }
    }

    // Function to load cities from a JSON file
    func loadCitiesFromJSONFile() -> [City] {
        guard let jsonFileURL = Bundle.module.url(forResource: "netherlands_cities", withExtension: "json") else {
            logger.log("netherlands_cities JSON file not found", level: .error)
            return []
        }
        do {
            let data = try Data(contentsOf: jsonFileURL)
            let decoder = JSONDecoder()
            let cities = try decoder.decode([City].self, from: data)
            return cities
        } catch {
            logger.log("Error loading or decoding JSON: \(error)", level: .error)
        }
        return []
    }

    func searchFor(cityName: String) -> City? {
        let cities =  loadCitiesFromJSONFile()
        return cities.first { city in
            city.city.lowercased() == cityName.lowercased()
        }
    }
}
