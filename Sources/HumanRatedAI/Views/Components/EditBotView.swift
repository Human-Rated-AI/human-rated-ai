// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  EditBotView.swift
//  human-rated-ai
//
//  Created by Claude on 4/3/25.
//

import SkipKit
import SwiftUI

struct EditBotView: View {
    // Callback for when the bot is updated
    var onBotUpdated: ((AISetting) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: EditAISettingViewModel
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
    init(bot: AISetting, onBotUpdated: ((AISetting) -> Void)? = nil) {
        self.onBotUpdated = onBotUpdated
        // Create a defensive copy of the bot to prevent unexpected modifications
        let botCopy = AISetting(
            id: bot.id,
            caption: bot.caption,
            desc: bot.desc,
            imageURL: bot.imageURL,
            isOpenSource: bot.isOpenSource,
            isPublic: bot.isPublic,
            name: bot.name,
            prefix: bot.prefix,
            suffix: bot.suffix,
            welcome: bot.welcome
        )
        self._viewModel = StateObject(wrappedValue: EditAISettingViewModel(originalBot: botCopy))
    }
    
    var body: some View {
#if os(Android)
        // Android uses NavigationStack with sheet presentation
        NavigationStack {
            AISettingFormView(viewModel: viewModel,
                              action: updateAIBot,
                              actionLabel: "Update",
                              isEdit: true,
                              showBottomButton: true)
            .navigationTitle("Edit AI Bot")
            .disabled(viewModel.isActionInProgress || viewModel.isUploading)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    AISettingToolbarButton(
                        viewModel: viewModel,
                        action: updateAIBot,
                        isEdit: true
                    )
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your AI bot has been updated successfully!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .onDisappear {
                // Cancel any ongoing tasks when view disappears
                viewModel.imageURLDebounceTask?.cancel()
                viewModel.imageURLDebounceTask = nil
            }
        }
#else
        // iOS uses direct NavigationLink presentation
        AISettingFormView(viewModel: viewModel,
                          action: updateAIBot,
                          actionLabel: "Update",
                          isEdit: true,
                          showBottomButton: true)
        .navigationTitle("Edit AI Bot")
        .disabled(viewModel.isActionInProgress || viewModel.isUploading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                AISettingToolbarButton(
                    viewModel: viewModel,
                    action: updateAIBot,
                    isEdit: true
                )
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your AI bot has been updated successfully!")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onDisappear {
            // Cancel any ongoing tasks when view disappears
            viewModel.imageURLDebounceTask?.cancel()
            viewModel.imageURLDebounceTask = nil
        }
#endif
    }
    
    // MARK: - Actions
    private func updateAIBot() {
        guard let user = authManager.user else {
            viewModel.errorMessage = "You must be logged in to update an AI bot"
            showErrorAlert = true
            return
        }
        
        guard viewModel.aiSetting.name.notEmptyTrimmed else {
            viewModel.errorMessage = "Please provide a name for your AI bot"
            showErrorAlert = true
            return
        }
        
        // Disable dismiss gestures during update
        viewModel.isUpdating = true
        
        // Save the trimmed version to avoid empty strings
        var botToUpdate = viewModel.aiSetting.trimmed
        
        Task {
            do {
                // If there's a selected image, upload it first
                if viewModel.selectedImage != nil, viewModel.imageURLString.isEmptyTrimmed {
                    if let downloadURL = try await viewModel.uploadImageToStorage(userID: user.uid) {
                        botToUpdate.imageURL = downloadURL
                    }
                } else if viewModel.imageURLString.notEmptyTrimmed &&
                            viewModel.aiSetting.imageURL?.absoluteString != viewModel.imageURLString {
                    botToUpdate.imageURL = URL(string: viewModel.imageURLString)
                }
                
                // Update the AI setting in Firestore only if there are changes
                if viewModel.hasChanges {
                    let _ = try await FirestoreManager.shared.updateAISetting(botToUpdate, userID: user.uid)
                    
                    // Using MainActor to update UI state
                    await MainActor.run {
                        viewModel.isUpdating = false
                        // Always call the callback when we actually updated something
                        onBotUpdated?(botToUpdate)
                        showSuccessAlert = true
                    }
                } else {
                    // No changes were made, just dismiss
                    await MainActor.run {
                        viewModel.isUpdating = false
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.isUpdating = false
                    viewModel.errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}
