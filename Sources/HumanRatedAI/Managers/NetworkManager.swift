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
    
    // Get available models from the API
    func getModels() async throws -> [String] {
        let key = EnvironmentManager.ai.aiKey?.md5 ?? ""
        let data = try await getData("models", headers: ["client-key": key])
        return try decodeModels(from: data)
    }
    
    func decodeModels(from data: Data) throws -> [String] {
        let decoder = JSONDecoder()
        let modelsResponse = try decoder.decode(ModelsResponse.self, from: data)
        return modelsResponse.data.map { $0.id }
    }
    
    // Supporting HTTP POST request function
    func postRequest(_ path: String? = nil, body: [String: Any], headers: [String: String]? = nil) async throws -> Data {
        var request = urlRequest(path, headers: headers)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert body to JSON data
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
    
    // Send a text prompt to the AI
    func sendTextPrompt(prompt: String, parameters: [String: Any]? = nil) async throws -> String {
        // Start with basic request body
        var body: [String: Any] = [
            "client_key": EnvironmentManager.ai.aiKey?.md5 ?? "",
            "prompt": prompt
        ]
        
        // Handle parameters in a way that avoids [String: Any] casts
        if var params = parameters {
            // Add provider if not specified
            if params["provider"] == nil {
                let savedProvider = UserDefaults.standard.string(forKey: "aiProvider")
                let defaultProvider = EnvironmentManager.ai.aiProvider
                params["provider"] = savedProvider ?? defaultProvider
            }
            body["params"] = params
        } else {
            // No parameters provided, create new params with provider
            let savedProvider = UserDefaults.standard.string(forKey: "aiProvider")
            let defaultProvider = EnvironmentManager.ai.aiProvider
            body["params"] = ["provider": savedProvider ?? defaultProvider]
        }
        
        // Send the request
        let data = try await postRequest("openai", body: body)
        
        // Convert data to string
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        return responseString
    }
    
    // Analyze image with AI vision
    func analyzeImage(imageURL: URL, prompt: String? = nil, parameters: [String: Any]? = nil) async throws -> String {
        // Start with clean parameters
        var params = parameters ?? [:]
        params["isVision"] = true
        
        // Add default provider if not specified
        if params["provider"] == nil {
            let savedProvider = UserDefaults.standard.string(forKey: "aiProvider")
            let defaultProvider = EnvironmentManager.ai.aiProvider
            params["provider"] = savedProvider ?? defaultProvider
        }
        
        // Create messages in the format expected by the server
        let messageContent: [[String: Any]] = [
            ["type": "image_url", "image_url": ["url": imageURL.absoluteString]],
            ["type": "text", "text": prompt ?? "Please describe this image"]
        ]
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": messageContent
            ]
        ]
        
        // Prepare the request body
        let body: [String: Any] = [
            "client_key": EnvironmentManager.ai.aiKey?.md5 ?? "",
            "messages": messages,
            "params": params
        ]
        
        // Send the request
        let data = try await postRequest("openai", body: body)
        
        // Convert data to string
        guard let responseString = String(data: data, encoding: .utf8) else {
            throw URLError(.badServerResponse)
        }
        
        return responseString
    }
}
