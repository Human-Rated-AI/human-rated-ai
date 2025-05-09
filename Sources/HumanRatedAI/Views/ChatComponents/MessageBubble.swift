// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  MessageBubble.swift
//  human-rated-ai
//
//  Created by Claude 3.7 Sonet, Denis Bystruev on 4/8/25.
//

import SwiftUI

struct MessageBubble: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: Message
    let botImageURL: URL?
    let maxWidth: CGFloat
    
    // Calculate effective max width accounting for avatar space
    private var effectiveMaxWidth: CGFloat {
        // Account for avatar width (32) + spacing (8)
        return max(maxWidth - 40, maxWidth * 0.7)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            } else {
                // Bot avatar
                AvatarView(imageURL: botImageURL, width: 32, height: 32)
            }
            
            // Message bubble
            Text(message.content)
                .padding(12)
                .background(message.isUser ? Color.blue : (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)))
                .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                .cornerRadius(16)
                .frame(maxWidth: effectiveMaxWidth, alignment: message.isUser ? .trailing : .leading)
            
            if message.isUser {
                // User avatar (placeholder - this would use user's avatar in a real implementation)
                let userAvatarURL: URL? = nil // Replace with actual user avatar URL
                AvatarView(imageURL: userAvatarURL, width: 32, height: 32)
            } else {
                Spacer()
            }
        }
    }
}
