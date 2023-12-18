//
//  FundaConfig.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation

struct SearchConfig: Decodable {
    let selectedAreas: [String]
    let price: String
    let floorArea: String
    let availability: String
    let bedrooms: String
    let objectType: String
    let publicationDate: String

    static func loadParameters(configString: String) throws -> SearchConfig {
        let data = Data(configString.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(SearchConfig.self, from: data)
    }
}
