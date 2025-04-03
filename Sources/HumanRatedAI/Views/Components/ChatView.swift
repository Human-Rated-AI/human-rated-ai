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
import SkipKit

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var deleteError: String?
    @State private var isDeleting = false
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showEditView = false
    @State private var showErrorAlert = false
    @State var bot: AISetting
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
        // On iOS, we use NavigationLink instead of sheet for better alert handling
        .background(
            NavigationLink(destination: EditBotView(bot: bot, onBotUpdated: { updatedBot in
                self.bot = updatedBot
            }), isActive: $showEditView) {
                EmptyView()
            }
                .opacity(0)
        )
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
