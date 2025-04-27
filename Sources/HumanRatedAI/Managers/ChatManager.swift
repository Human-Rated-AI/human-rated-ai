// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ChatManager.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 4/27/25.
//

import Foundation
import SwiftUI

class ChatManager: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isProcessing = false
    @Published var error: String?
    
    private let authManager = AuthManager.shared
    private let networkManager = NetworkManager.ai
    
    // Send a message to the AI service
    func sendMessage(_ text: String, bot: AISetting) async throws -> String {
        // Update state on main thread
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        // Add user message to conversation
        let userMessage = Message(content: text, isUser: true, timestamp: Date())
        await MainActor.run {
            messages.append(userMessage)
        }
        
        do {
            // Prepare parameters with current deployment
            var params: [String: Any] = [String: Any]()
            
            // Add prefix if available
            if let prefix = bot.prefix, !prefix.isEmpty {
                params["prefix"] = prefix
            }
            
            // Add suffix if available
            if let suffix = bot.suffix, !suffix.isEmpty {
                params["suffix"] = suffix
            }
            
            // Add system prompt if available
            if let desc = bot.desc, !desc.isEmpty {
                params["system"] = desc
            }
            
            // Send request to AI server
            let response = try await networkManager?.sendTextPrompt(prompt: text, parameters: params)
            
            // Add AI response to conversation
            if let response = response {
                let assistantMessage = Message(content: response, isUser: false, timestamp: Date())
                await MainActor.run {
                    messages.append(assistantMessage)
                    isProcessing = false // Set isProcessing to false on main thread
                }
                return response
            } else {
                await MainActor.run {
                    isProcessing = false // Set isProcessing to false on main thread
                }
                throw NSError(domain: "ChatManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No response received"])
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isProcessing = false // Set isProcessing to false on main thread
            }
            throw error
        }
    }
    
    // Send an image for analysis
    func sendImage(_ image: UIImage, prompt: String? = nil, bot: AISetting) async throws -> String {
        // Update state on main thread
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        do {
            // Only proceed if there's a user
            guard let user = authManager.user else {
                await MainActor.run {
                    isProcessing = false
                }
                throw NSError(domain: "ChatManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            }
            
            // Generate a unique path for the image
            let imagePath = StorageManager.shared.generateUniqueFilePath(
                for: user.uid,
                fileType: "ai_settings",
                fileExtension: "jpg"
            )
            
            // Upload the image to Firebase Storage
            let imageURL = try await StorageManager.shared.uploadImage(
                image,
                to: imagePath,
                compressionQuality: 0.8
            )
            
            // Prepare parameters
            var params: [String: Any] = [String: Any]()
            
            // Add system prompt if available
            if let desc = bot.desc, !desc.isEmpty {
                params["system"] = desc
            }
            
            // Add caption (vision prompt) if available
            let visionPrompt = bot.caption?.nonEmptyTrimmed ?? prompt ?? "Please describe what you see in this image"
            
            // Send the image for analysis
            let response = try await networkManager?.analyzeImage(imageURL: imageURL, prompt: visionPrompt, parameters: params)
            
            // Add the exchange to conversation 
            if let response = response {
                await MainActor.run {
                    messages.append(Message(content: visionPrompt, isUser: true, timestamp: Date()))
                    messages.append(Message(content: response, isUser: false, timestamp: Date()))
                    isProcessing = false // Set isProcessing to false on main thread
                }
                return response
            } else {
                await MainActor.run {
                    isProcessing = false // Set isProcessing to false on main thread
                }
                throw NSError(domain: "ChatManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "No response received"])
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isProcessing = false // Set isProcessing to false on main thread
            }
            throw error
        }
    }
    
    // Clear conversation history
    func clearHistory() {
        messages.removeAll()
        error = nil
    }
}
