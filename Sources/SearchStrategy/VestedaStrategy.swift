//
//  VestedaStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 02/10/2023.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class VestedaStrategy: SearchStrategy {

    var logger: LoggerProtocol = ProxyLogger(category: "Vesteda")

    struct Property: Codable {
        let id: Int
        let imageBig: String
        let url: String
        let status: Int
    }

    // Define a struct to represent the results
    struct Results: Codable {
        let results: ResultsData
    }

    // Define a struct to represent the data inside "results"
    struct ResultsData: Codable {
        let items: [Property]
    }

    func search(fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig

        config.selectedAreas.forEach { area in
            Task {
                guard let httpBody = try? mapTaskToJSON(cityName: area, fundaTask: fundaTask) else {
                    return
                }
                // Call the async function to fetch data
                await fetchData(fundaTask: fundaTask, httpBody: httpBody)

            }
        }
    }

    // Create an async function to perform the network request
    private func fetchData(fundaTask: FundaTask, httpBody: [String: Any]) async {

        let jsonData = try? JSONSerialization.data(withJSONObject: httpBody)
        // Create the URL and request
        let apiUrl = URL(string: "https://www.vesteda.com/api/units/search/facet")!
        //https://www.vesteda.com/api/units/search/facet
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")
        request.httpBody = jsonData

        do {

            // Send the request and wait for the response
            #if canImport(FoundationNetworking)
                        let (data, _) = try await FoundationNetworking.URLSession.shared.fetchData(for: request)
            #else
                        let (data, _) = try await URLSession.shared.data(for: request)

            #endif
            // Parse the JSON response using Codable
            let decoder = JSONDecoder()
            let results = try decoder.decode(Results.self, from: data)

            // Access the properties inside the "week" array
            let properties = results.results.items
            var propertyURLs: [String] = []

            // Process the properties
            for property in properties where property.status == 1 {
                propertyURLs.append("https://www.vesteda.com\(property.url)")
            }

            await sendLinks(fundaTask: fundaTask, propertyURLs: propertyURLs)

        } catch {
            logger.log(error.localizedDescription, level: .error)
        }
    }

    private func mapTaskToJSON(cityName: String, fundaTask: FundaTask) throws -> [String: Any]? {
        // https://www.vesteda.com/nl/woning-zoeken?placeType=1&sortType=1&radius=5&s=Utrecht,%20Nederland&sc=woning&latitude=52.090736&longitude=5.12142&filters=0&priceFrom=500&priceTo=2000

        guard let city = searchFor(cityName: cityName) else { throw FundaGoldError.jsonParsingFailed  }

        // Extract specific values
        let filters = [0]
        let place = city.city
        let latitude = Double(city.lat) ?? 0.0
        let longitude = Double(city.lng) ?? 0.0
        let placeType = 1
        let radius = 5
        let sorting = 0
        let priceFrom = 0
        let priceTo = Int(fundaTask.searchConfig.price) ?? 0

        // Create the JSON object
        let jsonObject: [String: Any] = [
            "filters": filters,
            "latitude": latitude,
            "longitude": longitude,
            "place": place,
            "placeType": placeType,
            "radius": radius,
            "sorting": sorting,
            "priceFrom": priceFrom,
            "priceTo": priceTo,
            "language": "en"
        ]
        return jsonObject
    }
}
