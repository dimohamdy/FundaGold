//
//  IkwilhurenStrategy.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 11/10/2023.
//

import Foundation
import SwiftSoup
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// Define the City model
struct City: Codable {
    let city: String
    let lat: String
    let lng: String
}

class IkwilhurenStrategy: SearchStrategy {

    var logger: LoggerProtocol = ProxyLogger(category: "Ikwilhuren")

    var csrf: String = ""
    var cookies: [HTTPCookie] = []

    // Define a function to send the initial request and retrieve cookies
    func sendInitialRequest() async throws {
        let url = URL(string: "https://ikwilhuren.nu/aanbod")!
        let request = URLRequest(url: url)
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let (data, _) = try await session.data(with: request)

        if let cookies = URLSession.shared.configuration.httpCookieStorage?.cookies(for: url) {
            self.cookies = cookies
        }

        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw FundaGoldError.invalidURL
        }

        // Parse the HTML content using SwiftSoup
        let doc = try? SwiftSoup.parse(htmlString)

        // Select the input element with name="csrf"
        // Check if the element was found
        if let csrfElement = try? doc?.select("input[name=csrf]").first(), let csrfToken = try? csrfElement.attr("value") {
            csrf =  csrfToken
        } else {
            throw FundaGoldError.requestFailed
        }

    }

    func search(fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig
        try await sendInitialRequest()

        for city in config.selectedCities {

            if let city =  searchFor(cityName: city) {
                try await run(city: city, fundaTask: fundaTask)
            }
        }
    }

    @Sendable func run(city: City, fundaTask: FundaTask) async throws {
        let config = fundaTask.searchConfig

        let session = URLSession(configuration: URLSessionConfiguration.default)

        // Define the URL and the form data
        let url = URL(string: "https://ikwilhuren.nu/aanbod/") // Replace with the actual URL
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"

        let formData = [
            "postrequest": "doeFilter",
            "objSearch": "{\"weergavenaam\":\"Gemeente \(city.city)\",\"lat\":\(city.lat),\"lng\":\(city.lng)}",
            "selAfstand": "10",
            "csrf": csrf,
            "selPrijsVan": "0",
            "selPrijsTot": "\(config.maxRentAmount)",
            "selWoonoppervlakteVan": "0",
            "selWoonoppervlakteTot": "\(config.minFloorArea)",
            "selWoninghoofdtypeId": "2",
            "selSlaapkamersVan": "\(config.bedrooms)"
        ]

        let formString = formData.map { key, value in
            return "\(key)=\(value)"
        }.joined(separator: "&")

        request.httpBody = formString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(getRandomUserAgent(), forHTTPHeaderField: "User-Agent")

        // 302 Found
        // Crash in EasyHandle.set(preferredReceiveBufferSize:) + 200 in libFoundationNetworking.so
         let (_, response) = try await session.data(with: request)

        // Define an asynchronous function to send the POST request
//        let response = try await withCheckedThrowingContinuation { continuation in
//            session.dataTask(with: request) { data, response, error in
//                if let response = response {
//                    continuation.resume(returning: response)
//                } else if let error = error {
//                    continuation.resume(throwing: FundaGoldError.requestFailed)
//
//                }
//            }.resume()
//        }

        // Handle the response and errors here
        guard let httpResponse = response as? HTTPURLResponse, (200..<302).contains(httpResponse.statusCode) else {
            return
        }

        let htmlString = try await fetchHTML(from: url!)
        // Parse the HTML content using SwiftSoup
        let doc = try SwiftSoup.parse(htmlString)

        // Select all anchor elements with the class "stretched-link"
        let links = try doc.select("a.stretched-link")
        var propertyURLs: [String] = []

        // Iterate through the selected elements and extract the href attribute values
        links.compactMap { try? $0.attr("href") }
            .map { "https://ikwilhuren.nu\($0)" }
            .forEach {
                propertyURLs.append($0)
            }

        await sendLinks(fundaTask: fundaTask, propertyURLs: propertyURLs)
    }
}
