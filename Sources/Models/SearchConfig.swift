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
     "availability": "available",
     "bedrooms": "2",
     "objectType": "apartment",
     "publicationSinceDays": "1"
 }
 */

struct SearchConfig: Decodable {
    let selectedCities: [String]
    let maxRentAmount: String
    let minFloorArea: String
    let availability: String
    let bedrooms: String
    let objectType: String
    let publicationSinceDays: String

    static func loadParameters(configString: String) throws -> SearchConfig {
        let data = Data(configString.utf8)
        let decoder = JSONDecoder()
        return try decoder.decode(SearchConfig.self, from: data)
    }
}
