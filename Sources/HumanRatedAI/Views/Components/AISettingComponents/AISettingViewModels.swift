// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AISettingViewModels.swift
//  human-rated-ai
//
//  Created by Claude on 4/3/25.
//

import SkipKit
import SwiftUI

// Base class for common AI Setting view model functionality
class BaseAISettingViewModel: ObservableObject {
    @Published public var aiSetting: AISetting
    @Published public var errorMessage = ""
    @Published public var hasChanges = false
    @Published var imageURLDebounceTask: Task<Void, Never>?
    @Published public var imageURLString = ""
    @Published public var isOpenSource: Bool
    @Published public var isPublic: Bool
    @Published public var isUploading = false
    @Published public var selectedImage: UIImage?
    @Published public var selectedMediaURL: URL?
    @Published public var urlUpdateCounter = 0
    
    init(aiSetting: AISetting) {
        self.aiSetting = aiSetting
        self.isOpenSource = aiSetting.isOpenSource
        self.isPublic = aiSetting.isPublic
        
        // Initialize the URL string if there is an imageURL
        if let imageURL = aiSetting.imageURL {
            self.imageURLString = imageURL.absoluteString
        }
    }
    
    // Common functionality for processing image URL strings
    public func processImageURLString(_ newValue: String) {
        // Store the string value
        imageURLString = newValue
        
        // Cancel any previous task
        imageURLDebounceTask?.cancel()
        
        // Don't try to process empty or very short URLs
        if newValue.count < 10 {
            // Clear image URL if text is too short
            if aiSetting.imageURL != nil {
                aiSetting.imageURL = nil
                urlUpdateCounter += 1
                checkForChanges()
            }
            return
        }
        
        // Create new debounce task with 500ms delay
        imageURLDebounceTask = Task {
            // Wait for user to stop typing (500ms)
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Check if task was cancelled during the delay
            if Task.isCancelled { return }
            
            // Now try to process the URL
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if let imageURL = URL(string: newValue), imageURL.canOpen {
                    let oldURL = self.aiSetting.imageURL
                    self.aiSetting.imageURL = imageURL
                    // Clear selected image if URL is provided manually
                    self.selectedImage = nil
                    self.selectedMediaURL = nil
                    // Increment counter to force view update
                    self.urlUpdateCounter += 1
                    
                    // Check if URL has changed
                    if oldURL != imageURL {
                        self.checkForChanges()
                    }
                }
            }
        }
    }
    
    // Method to upload an image to storage
    func uploadImageToStorage(userID: String) async throws -> URL? {
        guard let image = selectedImage else { return nil }
        
        await MainActor.run {
            isUploading = true
        }
        
        do {
            let path = StorageManager.shared.generateUniqueFilePath(
                for: userID,
                fileType: "ai_settings",
                fileExtension: "jpg"
            )
            let downloadURL = try await StorageManager.shared.uploadImage(
                image,
                to: path,
                compressionQuality: 0.75
            )
            
            await MainActor.run {
                isUploading = false
            }
            
            return downloadURL
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isUploading = false
            }
            throw error
        }
    }
    
    // Stub for checking changes - to be implemented by subclasses
    public func checkForChanges() {
        // Base implementation does nothing
    }
}

// MARK: - Create View Model
class CreateAISettingViewModel: BaseAISettingViewModel, AISettingViewModel {
    @Published var isSaving = false
    
    public var isActionInProgress: Bool {
        isSaving
    }
    
    override init(aiSetting: AISetting = AISetting(name: "")) {
        super.init(aiSetting: aiSetting)
    }
    
    override func checkForChanges() {
        // Create view doesn't need to track changes
        hasChanges = true
    }
    
    func resetForm() {
        aiSetting = AISetting(name: "")
        // Cancel any pending URL processing
        imageURLDebounceTask?.cancel()
        imageURLDebounceTask = nil
        imageURLString = ""
        isOpenSource = false
        isPublic = false
        selectedImage = nil
        selectedMediaURL = nil
        urlUpdateCounter = 0
        errorMessage = ""
    }
}

// MARK: - Edit View Model
class EditAISettingViewModel: BaseAISettingViewModel, AISettingViewModel {
    private let originalBot: AISetting
    @Published var isUpdating = false
    
    public var isActionInProgress: Bool {
        isUpdating
    }
    
    init(originalBot: AISetting) {
        self.originalBot = originalBot
        super.init(aiSetting: originalBot)
    }
    
    override func checkForChanges() {
        // Check if any properties have changed from the original bot
        let nameChanged = originalBot.name != aiSetting.name
        let descChanged = originalBot.desc != aiSetting.desc
        let isPublicChanged = originalBot.isPublic != aiSetting.isPublic
        let isOpenSourceChanged = originalBot.isOpenSource != aiSetting.isOpenSource
        let captionChanged = originalBot.caption != aiSetting.caption
        let prefixChanged = originalBot.prefix != aiSetting.prefix
        let suffixChanged = originalBot.suffix != aiSetting.suffix
        let welcomeChanged = originalBot.welcome != aiSetting.welcome
        
        // Special handling for image URL since they can be complex objects
        let imageURLChanged: Bool
        if let originalURL = originalBot.imageURL?.absoluteString,
           let currentURL = aiSetting.imageURL?.absoluteString {
            imageURLChanged = originalURL != currentURL
        } else {
            imageURLChanged = (originalBot.imageURL == nil) != (aiSetting.imageURL == nil)
        }
        
        hasChanges = nameChanged || descChanged || isPublicChanged || isOpenSourceChanged ||
                    captionChanged || prefixChanged || suffixChanged || welcomeChanged ||
                    imageURLChanged || selectedImage != nil
    }
}
