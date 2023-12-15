//
//  ParariusSearchStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct ParariusSearchStrategy: SearchStrategy {

    var logger: LoggerProtocol = ProxyLogger(category: "Pararius")

    // https://www.pararius.nl/huurwoningen/almere/1100-1500/2-slaapkamers/75m2

    func search(fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig

        var linksForCities: [URL] = []
        config.selectedAreas.forEach { area in
            // Construct the URL with query parameters
            let baseURL = "https://www.pararius.nl/huurwoningen"
            // Query parameters
            let priceRange = "0-\(config.price)"
            let bedrooms = "\(config.bedrooms)-slaapkamers"
            let floorArea = "\(config.floorArea)m2"

            // Construct the path with query parameters
            let path = "/\(area.lowercased())/\(priceRange)/\(bedrooms)/\(floorArea)/sinds-1"

            guard let url =  URL(string: baseURL + path)  else {
                logger.log("Invalid URL", level: .error)
                return
            }
            linksForCities.append(url)

        }

        await fetchAndProcessLinks(fundaTask: fundaTask, linksForCities: linksForCities)
    }

    private func fetchAndProcessLinks(fundaTask: FundaTask, linksForCities: [URL]) async {
        var propertyURLs: [String] = []

        for url in linksForCities {
            do {
                let htmlString = try await fetchHTML(from: url)
                let doc = try SwiftSoup.parse(htmlString)
                let links = try doc.select("h2.listing-search-item__title a.listing-search-item__link--title")

                links.compactMap { try? $0.attr("href") }
                     .map { "https://www.pararius.nl\($0)" }
                     .forEach { propertyURLs.append($0) }

                await sendLinks(fundaTask: fundaTask, propertyURLs: propertyURLs)

            } catch {
                logger.log(error.localizedDescription, level: .error)

            }
        }
    }
}
