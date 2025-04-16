// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  MessageInput.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 4/9/25.
//

import SwiftUI

struct MessageInput: View {
    @Binding var messageText: String
    @Environment(\.colorScheme) private var colorScheme
    let onSend: () -> Void
    
    private var sendMessageIcon: String {
#if os(Android)
        "chevron.up"
#else
        "arrow.up.circle.fill"
#endif
    }
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText)
                .padding(10)
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                .cornerRadius(20)
                .onSubmit {
                    onSend()
                }
            
            Button(action: onSend) {
                Image(systemName: sendMessageIcon)
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
            }
            .disabled(messageText.isEmptyTrimmed)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}
