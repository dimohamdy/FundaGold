//
//  FundaConfig.swift
//  FundaGold
//
//  Created by Dimo Abdelaziz on 01/10/2023.
//

import Foundation

/* User should send JSON look like this.
 {
     "selectedCities": [
         "Amsterdam", "Utrecht", "Amersfoort", "Nieuwegein", "Houten" , "Bussum"
     ],
     "maxRentAmount": "1500",
     "minFloorArea": "100",
     "bedrooms": "2"
 }
 */

struct SearchConfig: Decodable {
    let selectedCities: [String]
    let maxRentAmount: String
    let minFloorArea: String
    let bedrooms: String
    var availability: String { "available" }
    var objectType: String { "apartment" }
    var publicationSinceDays: String { "1" }

    static func loadParameters(configString: String) throws -> SearchConfig {
        let data = Data(configString.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(SearchConfig.self, from: data)
    }
}
