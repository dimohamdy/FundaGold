//
//  FundaSearchStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct FundaSearchStrategy: SearchStrategy {

    var logger: LoggerProtocol = ProxyLogger(category: "Funda")

    func search(fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig

        // Construct the URL with query parameters
        var urlComponents = URLComponents(string: "https://www.funda.nl/zoeken/huur")!
        urlComponents.queryItems = [
            URLQueryItem(name: "selected_area", value: config.selectedCities.map { "\"\($0.lowercased())\"" }.joined(separator: ",")),
            URLQueryItem(name: "price", value: "\"-\(config.maxRentAmount)\""),
            URLQueryItem(name: "floor_area", value: "\"\(config.minFloorArea)-\""),
            URLQueryItem(name: "availability", value: "[\"\(config.availability)\"]"),
            URLQueryItem(name: "bedrooms", value: "\"-\(config.bedrooms)\""),
            URLQueryItem(name: "object_type", value: "[\"\(config.objectType)\"]"),
            URLQueryItem(name: "publication_date", value: "\"\(config.publicationSinceDays)\"")
        ]

        guard let url = urlComponents.url else {
            logger.log("Invalid URL", level: .error)
            return
        }

        do {

            let htmlString = try await fetchHTML(from: url)
            // Parse the HTML content using SwiftSoup
            let doc = try SwiftSoup.parse(htmlString)

            // Find the script element with type="application/ld+json"
            let scriptElement = try doc.select("script[type=application/ld+json]").first()
            guard let scriptData = scriptElement?.data() else {
                return
            }

            let jsonObject = try parseJSON(from: scriptData)
            let propertyURLs = extractPropertyURLs(from: jsonObject)

            await sendLinks(fundaTask: fundaTask, propertyURLs: propertyURLs)

        } catch {
            logger.log(error.localizedDescription, level: .error)
        }
    }

    // Function to extract property URLs from JSON
    private func extractPropertyURLs(from jsonObject: [String: Any]) -> [String] {
        guard let itemListElement = jsonObject["itemListElement"] as? [[String: Any]] else {
            return []
        }

        let propertyURLs = itemListElement.compactMap { item -> String? in
            guard let url = item["url"] as? String, url.hasPrefix("https://www.funda.nl/huur/") else {
                return nil
            }
            return url
        }

        return propertyURLs
    }

}
