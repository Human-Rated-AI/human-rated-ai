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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State var bot: AISetting
    @State private var deleteError: String?
    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showEditView = false
    @State private var showErrorAlert = false
    @State private var messageText: String = ""
    @State private var messages: [Message] = []
    @State private var scrollProxy: ScrollViewProxy? = nil
    
    let isUserBot: Bool
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Small model name at the top
                HStack {
                    Text(bot.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    Spacer()
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                Divider()
                
                // Chat area with messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    botImageURL: bot.imageURL,
                                    maxWidth: geometry.size.width * 0.7
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                        // Add welcome message if available and messages array is empty
                        if messages.isEmpty, let welcome = bot.welcome, !welcome.isEmpty {
                            let welcomeMessage = Message(content: welcome, isUser: false, timestamp: Date())
                            messages.append(welcomeMessage)
                            // Scroll to the welcome message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy?.scrollTo(welcomeMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: messages) { _ in
                        // Scroll to the latest message
                        if let lastMessage = messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                // Message input area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .padding(10)
                        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                        .cornerRadius(20)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? Color.black : Color.white)
            }
            .alert("Delete Bot", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteBot()
                }
            } message: {
                Text("Are you sure you want to delete \(bot.name)? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteError ?? "Unknown error occurred")
            }
#if os(Android)
            .sheet(isPresented: $showEditSheet) {
                EditBotView(bot: bot, onBotUpdated: { updatedBot in
                    self.bot = updatedBot
                })
            }
#else
            // On iOS, use navigationDestination for better navigation handling
            .navigationDestination(isPresented: $showEditView) {
                EditBotView(bot: bot, onBotUpdated: { updatedBot in
                    self.bot = updatedBot
                })
            }
#endif
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(bot.name)
            // Use the ID modifier to ensure navigation title updates when bot changes
            .id("chatView-\(bot.id)-\(bot.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isUserBot {
                        HStack(spacing: 16) {
                            Button(action: {
#if os(Android)
                                showEditSheet = true
#else
                                showEditView = true
#endif
                            }) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                            
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
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Add user message
        let userMessage = Message(content: trimmedMessage, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        // Clear input field
        messageText = ""
        
        // Simulate bot response (in a real app, this would call an AI service)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            simulateBotResponse(to: trimmedMessage)
        }
    }
    
    private func simulateBotResponse(to userMessage: String) {
        // In a real implementation, this would call the AI service
        // For now, just return a simple response
        let responseContent = "This is a simulated response from \(bot.name). In a real implementation, this would be a response from the AI model. You said: \"\(userMessage)\""
        let botMessage = Message(content: responseContent, isUser: false, timestamp: Date())
        messages.append(botMessage)
    }
}

private extension ChatView {
    func deleteBot() {
        guard let user = authManager.user else { return }
        isDeleting = true
        Task {
            do {
                // Handle image deletion
                if let imageURL = bot.imageURL, StorageManager.shared.isUserUploadedImage(imageURL, userID: user.uid) {
                    // Check if the image is used by other bots before deleting
                    let isImageUsedByOthers = try await FirestoreManager.shared.isImageUsedByOtherBots(
                        imageURL: imageURL,
                        excludingBotID: bot.id
                    )
                    // Delete the image if it's not used by other bots
                    if isImageUsedByOthers.isFalse {
                        try await StorageManager.shared.deleteFileFromURL(imageURL)
                    }
                }
                // Delete the bot
                try await FirestoreManager.shared.deleteAISetting(documentID: bot.id, userID: user.uid)
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteError = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
