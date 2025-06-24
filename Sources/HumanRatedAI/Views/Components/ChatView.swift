// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ChatView.swift
//  human-rated-ai
//
//  Created by Claude 3.7 Sonet, Denis Bystruev on 3/30/25.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var deleteError: String?
    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showEditView = false
    @State private var showErrorAlert = false
    @State private var messageText: String = ""
    @State private var pendingImageURL: URL? = nil // Add pending image state
    @State private var scrollProxy: ScrollViewProxy? = nil
    @StateObject private var botManager: BotManager
    @StateObject private var chatManager = ChatManager()
    let botsManager: BotsManager?
    let isUserBot: Bool
    
    init(bot: AISetting, isUserBot: Bool, botsManager: BotsManager? = nil) {
        self._botManager = StateObject(wrappedValue: BotManager(bot: bot))
        self.botsManager = botsManager
        self.isUserBot = isUserBot
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Small model name at the top
                ChatHeader(botName: botManager.bot.name)
                    .id("header-\(botManager.bot.name)")  // Force header refresh
                
                // Chat area with messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(
                                    message: message,
                                    botImageURL: botManager.bot.imageURL,
                                    maxWidth: geometry.size.width * 0.7
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                        // Add welcome message if messages array is empty
                        if chatManager.messages.isEmpty {
                            let welcome = botManager.bot.welcome?.nonEmptyTrimmed ?? "Welcome to \(botManager.bot.name)!"
                            let welcomeMessage = Message(content: welcome, isUser: false, timestamp: Date())
                            chatManager.messages.append(welcomeMessage)
                            // Scroll to the welcome message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy?.scrollTo(welcomeMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onChange(of: chatManager.messages) { _ in
                        // Scroll to the latest message
                        if let lastMessage = chatManager.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // Image preview area
                if let pendingImageURL = pendingImageURL {
                    VStack {
                        HStack {
                            Text("Selected Image:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Remove") {
                                self.pendingImageURL = nil
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                        
                        AsyncImage(url: pendingImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 100)
                        }
                        .frame(maxHeight: 150)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onTapGesture {
                            // Allow user to change image by tapping on it
                            handleImageUpload()
                        }
                    }
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.05))
                }
                
                // Message input area
                MessageInput(
                    messageText: $messageText, 
                    onSend: sendMessage, 
                    onImageSelected: handleImageSelected,
                    hasPendingImage: pendingImageURL != nil,
                    isLoading: chatManager.isProcessing
                )
            }
            .onChange(of: chatManager.error) { newError in
                showErrorAlert = newError != nil
            }
            .alert("Delete Bot", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteBot()
                }
            } message: {
                Text("Are you sure you want to delete \(botManager.bot.name)? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(chatManager.error ?? deleteError ?? "Unknown error occurred")
            }
#if os(Android)
            .sheet(isPresented: $showEditSheet) {
                EditBotView(bot: botManager.bot, onBotUpdated: { updatedBot in
                    botManager.updateBot(updatedBot)
                    botsManager?.updateBot(updatedBot)
                })
            }
#else
            // On iOS, use the modern navigation destination modifier
            .navigationDestination(isPresented: $showEditView) {
                EditBotView(bot: botManager.bot, onBotUpdated: { updatedBot in
                    botManager.updateBot(updatedBot)
                    botsManager?.updateBot(updatedBot)
                })
            }
#endif
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("AI Chat")
            // Use the ID modifier to ensure navigation title updates when bot changes
            .id("chatView-\(botManager.bot.id)-\(botManager.bot.name)")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isUserBot {
                        HStack(spacing: 16) {
                            Button(action: {
                                // Ensure we're not in the middle of another operation
                                if !isDeleting && !showDeleteAlert && !showErrorAlert {
#if os(Android)
                                    showEditSheet = true
#else
                                    showEditView = true
#endif
                                }
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
        guard !chatManager.isProcessing else { return }
        
        // Create message with text and/or image
        let hasText = !messageText.isEmptyTrimmed
        let hasImage = pendingImageURL != nil
        
        // Don't send if there's neither text nor image
        guard hasText || hasImage else { return }
        
        let messageContent = messageText.nonEmptyTrimmed ?? ""
        let imageURL = pendingImageURL
        
        // Clear input fields
        messageText = ""
        pendingImageURL = nil
        
        // Send message to AI through ChatManager
        Task {
            do {
                _ = try await chatManager.sendMessage(messageContent, bot: botManager.bot, imageURL: imageURL)
            } catch {
                // Error will be handled by the ChatManager and displayed in the UI
                showErrorAlert = chatManager.error != nil
            }
        }
    }
    
    private func handleImageSelected(_ imageURL: URL) {
        print("📷 ChatView: Image selected: \(imageURL)")
        pendingImageURL = imageURL
    }
    
    private func handleImageUpload() {
        print("📷 ChatView: Image upload action triggered")
        // This function can be used to trigger image picker directly if needed
        // For now, image selection is handled through MessageInput
    }
}

private extension ChatView {
    func deleteBot() {
        guard let user = authManager.user else { return }
        isDeleting = true
        Task {
            do {
                let botID = botManager.bot.id
                
                // Remove from current user's favorites first (if it exists)
                do {
                    try await FirestoreManager.shared.removeFromFavorites(documentID: botID, userID: user.uid)
                } catch {
                    // It's OK if the bot wasn't in favorites - just log and continue
                    debug("WARN", ChatView.self,
                          "Bot wasn't in favorites or error removing from favorites: \(error.localizedDescription)")
                }
                
                // Handle image deletion
                if let imageURL = botManager.bot.imageURL, StorageManager.shared.isUserUploadedImage(imageURL, userID: user.uid) {
                    // Check if the image is used by other bots before deleting
                    let isImageUsedByOthers = try await FirestoreManager.shared.isImageUsedByOtherBots(
                        imageURL: imageURL,
                        excludingBotID: botManager.bot.id
                    )
                    // Delete the image if it's not used by other bots
                    if isImageUsedByOthers.isFalse {
                        try await StorageManager.shared.deleteFileFromURL(imageURL)
                    }
                }
                
                // Delete the bot from Firestore
                try await FirestoreManager.shared.deleteAISetting(documentID: botManager.bot.id, userID: user.uid)
                
                // Update the shared BotsManager to remove from collections
                await MainActor.run {
                    botsManager?.userBots.removeAll { $0.id == botID }
                    botsManager?.publicBots.removeAll { $0.id == botID }
                    botsManager?.userFavorites.removeAll { $0 == botID }
                }
                
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
