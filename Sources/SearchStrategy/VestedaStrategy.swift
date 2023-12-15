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
        guard let json = mapURLtoJSON(config.vestedaURL) else {
            return
        }
        config.selectedAreas.forEach { area in
            Task {
                var httpBody = json
                httpBody["place"] = area
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

    private func mapURLtoJSON(_ urlString: String) -> [String: Any]? {
        // Parse the URL
        if let url = URL(string: urlString), let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            // Extract query parameters
            var queryItems = [String: String]()
            if let items = components.queryItems {
                for item in items {
                    if let value = item.value {
                        queryItems[item.name] = value
                    }
                }
            }

            // Extract specific values
            let filtersString = queryItems["filters"] ?? ""
            let latitudeString = queryItems["latitude"] ?? ""
            let longitudeString = queryItems["longitude"] ?? ""
            let placeString = queryItems["s"] ?? ""
            let placeTypeString = queryItems["placeType"] ?? ""
            let radiusString = queryItems["radius"] ?? ""
            let priceFromString = queryItems["priceFrom"] ?? ""
            let priceToString = queryItems["priceTo"] ?? ""

            let filters = filtersString.components(separatedBy: ",").compactMap { Int($0) }
            let latitude = Double(latitudeString) ?? 0.0
            let longitude = Double(longitudeString) ?? 0.0
            let placeType = Int(placeTypeString) ?? 0
            let radius = Int(radiusString) ?? 0
            let sorting = 0
            let priceFrom = Int(priceFromString) ?? 0
            let priceTo = Int(priceToString) ?? 0

            let placeComponents = placeString.components(separatedBy: ",")
            let place = placeComponents.first ?? ""

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

        return nil
    }

}
