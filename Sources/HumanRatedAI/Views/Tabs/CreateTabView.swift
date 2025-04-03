// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  CreateTabView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 10/27/24.
//

import SkipKit
import SwiftUI

// Import our newly defined components

struct CreateTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = CreateAISettingViewModel()
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            AISettingFormView(viewModel: viewModel,
                              action: saveAIBot,
                              actionLabel: "Create AI Bot",
                              isEdit: false,
                              showBottomButton: true)
            .navigationTitle("Create AI Bot")
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    viewModel.resetForm()
                }
            } message: {
                Text("Your AI bot has been created successfully!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AISettingToolbarButton(
                        viewModel: viewModel,
                        action: saveAIBot,
                        isEdit: false
                    )
                }
            }
            .onDisappear {
                // Cancel any ongoing tasks when view disappears
                viewModel.imageURLDebounceTask?.cancel()
                viewModel.imageURLDebounceTask = nil
            }
        }
    }
}

private extension CreateTabView {
    func saveAIBot() {
        guard let user = authManager.user else {
            viewModel.errorMessage = "You must be logged in to create an AI bot"
            showErrorAlert = true
            return
        }
        guard viewModel.aiSetting.name.notEmptyTrimmed else {
            viewModel.errorMessage = "Please provide a name for your AI bot"
            showErrorAlert = true
            return
        }
        
        viewModel.isSaving = true
        viewModel.aiSetting.id = UUID().uuidString
        
        Task {
            do {
                // If there's a selected image, upload it first
                if viewModel.selectedImage != nil, viewModel.imageURLString.isEmptyTrimmed {
                    if let downloadURL = try await viewModel.uploadImageToStorage(userID: user.uid) {
                        viewModel.aiSetting.imageURL = downloadURL
                    }
                } else if viewModel.imageURLString.notEmptyTrimmed {
                    viewModel.aiSetting.imageURL = URL(string: viewModel.imageURLString)
                }
                
                // Save the AI setting to Firestore
                let documentID = try await FirestoreManager.shared.saveAISetting(viewModel.aiSetting, userID: user.uid)
                await MainActor.run {
                    viewModel.aiSetting.id = documentID
                    viewModel.isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.isSaving = false
                    showErrorAlert = true
                }
            }
        }
    }
}
