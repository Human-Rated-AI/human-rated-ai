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
    // Constants
    private let MAX_HISTORY_MESSAGES = 25
    
    // Published properties
    @Published var messages: [Message] = []
    @Published var isProcessing = false
    @Published var error: String?
    
    // Dependencies
    private let authManager = AuthManager.shared
    private let networkManager = NetworkManager.ai
    
    // Get current date and time for system message
    private func getCurrentDateTime() -> (date: String, time: String) {
        let now = Date()
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        let date = dateFormatter.string(from: now)
        
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        let time = dateFormatter.string(from: now)
        
        return (date, time)
    }
    
    // Send a message to the AI service using conversation history
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
            // Get current date and time
            let dateTime = getCurrentDateTime()
            
            // Add system prompt if available, with date and time
            var systemPrompt = bot.desc ?? ""
            if !systemPrompt.isEmpty {
                systemPrompt = systemPrompt.replacingOccurrences(of: "${DATE}", with: dateTime.date)
                systemPrompt = systemPrompt.replacingOccurrences(of: "${TIME}", with: dateTime.time)
            }
            
            // Prepare conversation history for the API
            var historyMessages = [MessageModel]()
            
            // Add system message if available
            if !systemPrompt.isEmpty {
                historyMessages.append(MessageModel(role: "system", content: systemPrompt))
            }
            
            // Add prefix if available
            if let prefix = bot.prefix, !prefix.isEmpty {
                historyMessages.append(MessageModel(role: "system", content: prefix))
            }
            
            // Add conversation history
            // Get previous messages (excluding the current user message we just added)
            let previousMessagesArray = Array(messages.dropLast())
            
            // Limit to maximum allowed messages
            let limitedMessages = previousMessagesArray.suffix(MAX_HISTORY_MESSAGES - 1)
            
            // Convert to API message models
            limitedMessages.forEach { message in
                historyMessages.append(MessageModel(
                    role: message.isUser ? "user" : "assistant",
                    content: message.content,
                    timestamp: message.timestamp
                ))
            }
            
            // Add the current user message
            historyMessages.append(MessageModel(role: "user", content: text, timestamp: Date()))
            
            // Add suffix if available
            if let suffix = bot.suffix, !suffix.isEmpty {
                historyMessages.append(MessageModel(role: "system", content: suffix))
            }
            
            // Log history messages for debugging
            debug("INFO", ChatManager.self, "Sending \(historyMessages.count) messages to AI")
            historyMessages.forEach { message in
                debug("DEBUG", ChatManager.self, "[\(message.role)]: \(message.content.prefix(50))\(message.content.count > 50 ? "..." : "")")
            }
            
            // Send request to AI server with history
            let response = try await networkManager?.sendChatWithHistory(
                messages: historyMessages
            )
            
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
    
    // Send an image for analysis using conversation history
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
            
            // Get current date and time
            let dateTime = getCurrentDateTime()
            
            // Add system prompt if available, with date and time
            var systemPrompt = bot.desc ?? ""
            if !systemPrompt.isEmpty {
                systemPrompt = systemPrompt.replacingOccurrences(of: "${DATE}", with: dateTime.date)
                systemPrompt = systemPrompt.replacingOccurrences(of: "${TIME}", with: dateTime.time)
            }
            
            // Prepare conversation history for the API
            var historyMessages = [MessageModel]()
            
            // Add system message if available
            if !systemPrompt.isEmpty {
                historyMessages.append(MessageModel(role: "system", content: systemPrompt))
            }
            
            // Add prefix if available
            if let prefix = bot.prefix, !prefix.isEmpty {
                historyMessages.append(MessageModel(role: "system", content: prefix))
            }
            
            // Add conversation history
            // Get previous messages
            let previousMessagesArray = Array(messages)
            
            // Limit to maximum allowed messages
            let limitedMessages = previousMessagesArray.suffix(MAX_HISTORY_MESSAGES - 1)
            
            // Convert to API message models
            limitedMessages.forEach { message in
                historyMessages.append(MessageModel(
                    role: message.isUser ? "user" : "assistant",
                    content: message.content,
                    timestamp: message.timestamp
                ))
            }
            
            // Add suffix if available
            if let suffix = bot.suffix, !suffix.isEmpty {
                historyMessages.append(MessageModel(role: "system", content: suffix))
            }
            
            // Add vision prompt
            let visionPrompt = bot.caption?.nonEmptyTrimmed ?? prompt ?? "Please describe what you see in this image"
            
            // Log history messages for debugging
            debug("INFO", ChatManager.self, "Sending image with \(historyMessages.count) history messages to AI")
            historyMessages.forEach { message in
                debug("DEBUG", ChatManager.self, "[\(message.role)]: \(message.content.prefix(50))\(message.content.count > 50 ? "..." : "")")
            }
            
            // Send request to AI server with history and image
            let response = try await networkManager?.sendImageWithHistory(
                imageURL: imageURL,
                prompt: visionPrompt,
                messages: historyMessages
            )
            
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
