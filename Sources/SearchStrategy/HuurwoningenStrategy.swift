//
//  HuurwoningenStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 02/10/2023.
//

import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class HuurwoningenStrategy: SearchStrategy {

    var logger: LoggerProtocol = ProxyLogger(category: "Vesteda")

    func search(fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig

       // "https://www.huurwoningen.nl/in/hilversum/? =0-1300&living_size=75&bedrooms=1"

        var linksForCities: [URL] = []
        config.selectedAreas.forEach { area in

            var urlComponents = URLComponents(string: "https://www.huurwoningen.nl/in/\(area)")!
            urlComponents.queryItems = [
                URLQueryItem(name: "price", value: "0-\(config.price)"),
                URLQueryItem(name: "bedrooms", value: "\(config.bedrooms)"),
                URLQueryItem(name: "living_size", value: "\(config.floorArea)")
            ]

            guard let url = urlComponents.url else {
                return
            }

            linksForCities.append(url)
        }

        await fetchAndProcessLinks(fundaTask: fundaTask, linksForCities: linksForCities)
    }

    private func fetchAndProcessLinks(fundaTask: FundaTask, linksForCities: [URL]) async {
        for url in linksForCities {

            do {
                let htmlString = try await fetchHTML(from: url)
                let doc = try SwiftSoup.parse(htmlString)
                // Select all anchor elements with the class "listing-search-item__link listing-search-item__link--title"
                let links = try doc.select("a.listing-search-item__link listing-search-item__link--title")
                var propertyURLs: [String] = []

                links.map { "https://www.huurwoningen.nl\($0)" }
                     .forEach { propertyURLs.append($0) }

                await sendLinks(fundaTask: fundaTask, propertyURLs: propertyURLs)

            } catch {
                logger.log(error.localizedDescription, level: .error)
            }
        }
    }
}
