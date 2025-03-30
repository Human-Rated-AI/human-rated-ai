// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ChatView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/30/25.
//
import SwiftUI

struct ChatView: View {
    let bot: AISetting
    
    var body: some View {
        VStack {
            Text("Chat with \(bot.name)")
                .font(.title)
                .padding()
            
            // Here you would add your chat interface components
            // For example, messages list, input field, etc.
            
            Spacer()
        }
        .navigationTitle(bot.name)
    }
}
