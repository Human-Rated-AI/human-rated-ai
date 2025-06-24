// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  Message.swift
//  human-rated-ai
//
//  Created by Claude 3.7 Sonet, Denis Bystruev on 4/8/25.
//

import Foundation

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let imageURL: URL? // Add support for images
    
    // Convenience initializer for text-only messages
    init(content: String, isUser: Bool, timestamp: Date) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.imageURL = nil
    }
    
    // Full initializer with image support
    init(content: String, isUser: Bool, timestamp: Date, imageURL: URL?) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.imageURL = imageURL
    }
}

extension Message: Equatable {
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
