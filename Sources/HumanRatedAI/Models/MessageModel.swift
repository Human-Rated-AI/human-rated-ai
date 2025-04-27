// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  MessageModel.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 4/27/25.
//

import Foundation

/// API-compatible message model for communication with AI services
struct MessageModel: Codable {
    var role: String  // "user", "assistant", or "system"
    var content: String
    var timestamp: Int?
    var deployment: String?
    
    enum CodingKeys: String, CodingKey {
        case role, content, timestamp, deployment
    }
    
    init(role: String, content: String, timestamp: Date? = nil, deployment: String? = nil) {
        self.role = role
        self.content = content
        if let timestamp = timestamp {
            self.timestamp = Int(timestamp.timeIntervalSince1970)
        }
        self.deployment = deployment
    }
    
    /// Convert from UI Message model to API MessageModel
    init(from message: Message) {
        self.role = message.isUser ? "user" : "assistant"
        self.content = message.content
        self.timestamp = Int(message.timestamp.timeIntervalSince1970)
    }
    
    /// Convert to UI Message model
    func toMessage() -> Message {
        Message(
            content: content,
            isUser: role == "user",
            timestamp: timestamp != nil ? Date(timeIntervalSince1970: TimeInterval(timestamp!)) : Date()
        )
    }
}

typealias MessageModels = [MessageModel]

extension Array where Element == Message {
    /// Convert UI messages to API message models
    func toMessageModels() -> [MessageModel] {
        map { MessageModel(from: $0) }
    }
}

extension Array where Element == MessageModel {
    /// Convert API message models to UI messages
    func toMessages() -> [Message] {
        map { $0.toMessage() }
    }
}
