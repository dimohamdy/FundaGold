//
//  URLSession+FetchData.swift
//  FundaGold
//
//  Created by BinaryBoy on 12/11/23.
//

import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking

    extension URLSession {
        func fetchData(for request: URLRequest) async throws -> (Data, URLResponse) {
            return try await withCheckedThrowingContinuation { [weak self] continuation in
                self?.dataTask(with: request) { data, response, error in
                    if let data = data, let response = response {
                        continuation.resume(returning: (data, response))
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: FundaGoldError.requestFailed)
                    }
                }.resume()
            }
        }
    }

#endif

extension URLSession {
    func data(with request: URLRequest) async throws -> (Data, URLResponse) {
        #if canImport(FoundationNetworking)
                return try await fetchData(for: request)
        #else
                return try await data(for: request)

        #endif
    }
}
