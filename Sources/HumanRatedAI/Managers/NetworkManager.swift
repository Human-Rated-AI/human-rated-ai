// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  NetworkManager.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 9/22/24.
//

import Foundation

public class NetworkManager {
    private let urlRequest: URLRequest
    
    private init(_ urlRequest: URLRequest) {
        self.urlRequest = urlRequest
    }
}

// MARK: - Generic
extension NetworkManager {
    func getData(_ path: String? = nil, headers: [String: String]? = nil) async throws -> Data {
        var request = urlRequest(path, headers: headers)
        request.httpMethod = "GET"
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    func urlRequest(_ path: String? = nil, headers: [String: String]? = nil) -> URLRequest {
        var request = urlRequest
        if let path {
            request.url = request.url?.appendingPathComponent(path)
        }
        if let headers {
            for (key, value) in headers {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        return request
    }
}

// MARK: - AI
extension NetworkManager {
    static var ai: NetworkManager? {
        guard let url = EnvironmentManager.ai.aiURL else { return nil }
        return NetworkManager(URLRequest(url: url))
    }
    
    func decodeDeployments(from data: Data) throws -> [Deployment] {
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(DeploymentsWrapper.self, from: data)
        return decodedData.value
    }
    
    func getDeployments() async throws -> [Deployment] {
        let key = EnvironmentManager.ai.aiKey?.md5 ?? ""
        let data = try await getData("deployments", headers: ["client-key": key])
        return try decodeDeployments(from: data)
    }
}
