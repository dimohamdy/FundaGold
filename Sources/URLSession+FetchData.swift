//
//  File.swift
//  
//
//  Created by BinaryBoy on 12/11/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking

 extension URLSession {
    func fetchData(for request: URLRequest) async throws -> (Data, URLResponse) {
        return await withCheckedContinuation { continuation in
            self.dataTask(with: request) { data, response, error in
            if let data = data, let response = response {
                    continuation.resume(returning: (data, response))
                } else {
                    // Handle unexpected case
                    fatalError("Unexpected result from dataTask")
                }
            }.resume()
        }
    }
 }

#endif
