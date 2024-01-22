//
//  WonenbijbouwinvestStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct WonenbijbouwinvestStrategy: SearchStrategy {

    var logger: LoggerProtocol = ProxyLogger(category: "Wonenbijbouwinvest")

    struct Property: Codable {
        // Define the structure of your JSON data
        // You can add more fields here as needed
        let name: String
        let description: String
        let url: String
    }

    struct ResponseData: Codable {
        let data: [Property]
    }

    //https://www.wonenbijbouwinvest.nl/huuraanbod?query=Utrecht&page=1&range=5&seniorservice=false&order=recent&propertyToggle=false&surface=lte-60&sleepingrooms=1&price=1000-1500&type=appartement&availability=&orientation=&showAvailable=

    func search(fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig

        var linksForCities: [URL] = []
        config.selectedCities.forEach { area in

            var urlComponents = URLComponents(string: "https://www.wonenbijbouwinvest.nl/api/search")!
            urlComponents.queryItems = [
                URLQueryItem(name: "query", value: area),
                URLQueryItem(name: "price", value: "0-\(config.maxRentAmount)"),
                URLQueryItem(name: "page", value: "1"),
                URLQueryItem(name: "range", value: "5"),
                URLQueryItem(name: "seniorservice", value: "false"),
                URLQueryItem(name: "order", value: "recent"),
                URLQueryItem(name: "propertyToggle", value: "false"),
                URLQueryItem(name: "sleepingrooms", value: "\(config.bedrooms)"),
                URLQueryItem(name: "type", value: "appartement"),
                URLQueryItem(name: "surface", value: "lte-\(config.minFloorArea)")
            ]

            guard let url = urlComponents.url else {
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
                var request = URLRequest(url: url)
                request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")

                // Perform the HTTP GET request using async/await
                let session = URLSession(configuration: URLSessionConfiguration.default)
                let (data, _) = try await session.data(with: request)

                // Parse the JSON data into a Property array
                let responseData = try JSONDecoder().decode(ResponseData.self, from: data)

                responseData.data.forEach { property in
                    propertyURLs.append(property.url)
                }
                await sendLinks(fundaTask: fundaTask, propertyURLs: propertyURLs)

            } catch {
                logger.log(error.localizedDescription, level: .error)
            }
        }

    }
}
