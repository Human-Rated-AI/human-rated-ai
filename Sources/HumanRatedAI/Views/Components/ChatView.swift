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
    @State private var showDeleteAlert = false
    let bot: AISetting
    let isUserBot: Bool
    
    var body: some View {
        VStack {
            Text("TODO: Chat interface")
                .font(.title)
                .padding()
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Here you would add your chat interface components
            // For example, messages list, input field, etc.
            
            Spacer()
        }
        .alert("Delete Bot", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete action will be implemented later
                debug("DEBUG", ChatView.self, "Confirmed delete action")
            }
        } message: {
            Text("Are you sure you want to delete \(bot.name)? This action cannot be undone.")
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(bot.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isUserBot {
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
