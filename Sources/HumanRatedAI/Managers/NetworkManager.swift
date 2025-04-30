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

enum NetworkError: Error, LocalizedError {
    case serverError(statusCode: Int, errorMessage: String)
    case connectionError(String)
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let statusCode, let errorMessage):
            return "Server error (\(statusCode)): \(errorMessage)"
        case .connectionError(let message):
            return "Connection error: \(message)"
        case .decodingError(let message):
            return "Data decoding error: \(message)"
        }
    }
}

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
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                debug("FAIL", Self.self, "Non-HTTP response received")
                throw URLError(.badServerResponse)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let responseText = String(data: data, encoding: .utf8) ?? "No response text"
                debug("FAIL", Self.self, "HTTP status code \(httpResponse.statusCode): \(responseText)")
                throw NetworkError.serverError(statusCode: httpResponse.statusCode, errorMessage: responseText)
            }
            return data
        } catch {
            debug("FAIL", Self.self, "Network request failed: \(error.localizedDescription)")
            if let networkError = error as? NetworkError {
                throw networkError
            } else {
                throw NetworkError.connectionError(error.localizedDescription)
            }
        }
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
        do {
            let decodedData = try decoder.decode(DeploymentsWrapper.self, from: data)
            return decodedData.value
        } catch {
            debug("FAIL", Self.self, "Failed to decode deployments: \(error.localizedDescription)")
            throw NetworkError.decodingError("Failed to decode deployments: \(error.localizedDescription)")
        }
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
        do {
            let modelsResponse = try decoder.decode(ModelsResponse.self, from: data)
            return modelsResponse.data.map { $0.id }
        } catch {
            debug("FAIL", Self.self, "Failed to decode models: \(error.localizedDescription)")
            throw NetworkError.decodingError("Failed to decode AI models: \(error.localizedDescription)")
        }
    }
    
    // Supporting HTTP POST request function
    func postRequest(_ path: String? = nil, body: [String: Any], headers: [String: String]? = nil) async throws -> Data {
        var request = urlRequest(path, headers: headers)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Convert body to JSON data
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                debug("FAIL", Self.self, "Non-HTTP response received for POST request")
                throw URLError(.badServerResponse)
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                let responseText = String(data: data, encoding: .utf8) ?? "No response text"
                debug("FAIL", Self.self, "HTTP POST status code \(httpResponse.statusCode): \(responseText)")
                throw NetworkError.serverError(statusCode: httpResponse.statusCode, errorMessage: responseText)
            }
            return data
        } catch let error as NetworkError {
            throw error
        } catch let error as NSError {
            if error.domain == NSURLErrorDomain {
                debug("FAIL", Self.self, "Network connection error: \(error.localizedDescription)")
                throw NetworkError.connectionError(error.localizedDescription)
            } else {
                debug("FAIL", Self.self, "Error in POST request: \(error.localizedDescription)")
                throw error
            }
        }
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
            // Remove provider if specified to avoid sending it to the server
            params["provider"] = nil
            body["params"] = params
        } else {
            // No parameters provided, create new params but without provider
            body["params"] = [String: Any]()
        }
        
        // Send the request
        let data = try await postRequest("openai", body: body)
        
        // Convert data to string
        guard let responseString = String(data: data, encoding: .utf8) else {
            debug("FAIL", Self.self, "Failed to decode response data as UTF-8 string")
            throw NetworkError.decodingError("Failed to decode server response")
        }
        
        return responseString
    }
    
    // Analyze image with AI vision
    func analyzeImage(imageURL: URL, prompt: String? = nil, parameters: [String: Any]? = nil) async throws -> String {
        // Start with clean parameters
        var params = parameters ?? [String: Any]()
        params["isVision"] = true
        
        // Remove provider parameter if specified
        params["provider"] = nil
        
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
            debug("FAIL", Self.self, "Failed to decode response data as UTF-8 string")
            throw NetworkError.decodingError("Failed to decode server response")
        }
        
        return responseString
    }
    
    // Send a message with history to the AI
    func sendChatWithHistory(messages: [MessageModel]) async throws -> String {
        // Start with basic request body
        let body: [String: Any] = [
            "client_key": EnvironmentManager.ai.aiKey?.md5 ?? "",
            "messages": messages.map { $0.toDictionary() },
            "params": [String: Any]()
        ]
        
        // Send the request
        let data = try await postRequest("openai", body: body)
        
        // Convert data to string
        guard let responseString = String(data: data, encoding: .utf8) else {
            debug("FAIL", Self.self, "Failed to decode response data as UTF-8 string")
            throw NetworkError.decodingError("Failed to decode server response")
        }
        
        return responseString
    }
    
    // Send an image with history to the AI
    func sendImageWithHistory(imageURL: URL, prompt: String, messages: [MessageModel]) async throws -> String {
        // Start with basic request body
        var body: [String: Any] = [
            "client_key": EnvironmentManager.ai.aiKey?.md5 ?? ""
        ]
        
        // Create the image message with content array
        let imageMessage: [String: Any] = [
            "role": "user",
            "content": [
                ["type": "image_url", "image_url": ["url": imageURL.absoluteString]],
                ["type": "text", "text": prompt]
            ]
        ]
        
        // Add image message to history
        let allMessages = messages.map { $0.toDictionary() }
        var messagesForAPI = allMessages
        messagesForAPI.append(imageMessage)
        
        body["messages"] = messagesForAPI
        
        // Set vision flag in parameters
        body["params"] = ["isVision": true]
        
        // Send the request
        let data = try await postRequest("openai", body: body)
        
        // Convert data to string
        guard let responseString = String(data: data, encoding: .utf8) else {
            debug("FAIL", Self.self, "Failed to decode response data as UTF-8 string")
            throw NetworkError.decodingError("Failed to decode server response")
        }
        
        return responseString
    }
}
