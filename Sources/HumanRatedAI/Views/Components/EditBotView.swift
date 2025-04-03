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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var errorMessage = ""
    @State private var imageURLDebounceTask: Task<Void, Never>?
    @State private var imageURLString = ""
    @State private var isOpenSource: Bool
    @State private var isPublic: Bool
    @State private var isUpdating = false
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    @State private var urlUpdateCounter = 0  // Track URL changes
    @State private var hasChanges = false    // Track if changes have been made
    
    // Media picker states
    @State private var isUploading = false
    @State private var selectedImage: UIImage?
    @State private var selectedMediaURL: URL?
    @State private var showMediaPicker = false
    @State private var pickerType: MediaPickerType = .library
    
    // Original and editable bot
    @State private var editedBot: AISetting
    private let originalBot: AISetting
    
    init(bot: AISetting) {
        self.originalBot = bot
        _editedBot = State(initialValue: bot)
        _isOpenSource = State(initialValue: bot.isOpenSource)
        _isPublic = State(initialValue: bot.isPublic)
        
        // Initialize the URL string if there is an imageURL
        if let imageURL = bot.imageURL {
            _imageURLString = State(initialValue: imageURL.absoluteString)
        }
    }
    
    var body: some View {
#if os(Android)
        // Android uses NavigationStack with sheet presentation
        NavigationStack {
            editForm
                .navigationTitle("Edit AI Bot")
                .disabled(isUpdating || isUploading)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
#else
        // iOS uses direct NavigationLink presentation
        editForm
            .navigationTitle("Edit AI Bot")
            .disabled(isUpdating || isUploading)
            .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    // Common form view used by both platforms
    private var editForm: some View {
        Form {
            Section(header: Text("Basic Information").font(.subheadline)) {
                TextField("Name", text: Binding(
                    get: { editedBot.name },
                    set: {
                        editedBot.name = $0
                        checkForChanges()
                    }
                ))
                .font(.body)
                ZStack(alignment: .topLeading) {
                    if editedBot.desc?.isEmptyTrimmed != false {
                        Text("Description")
                            .font(.body)
#if os(Android)
                            .foregroundColor(Color.gray)
                            .opacity(0.67)
                            .padding(.leading, 12)
                            .padding(.top, 18)
#else
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
#endif
                    }
                    
                    TextEditor(text: Binding(
                        get: { editedBot.desc ?? "" },
                        set: {
                            editedBot.desc = $0
                            checkForChanges()
                        }
                    ))
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, -4)
                    .frame(height: 100)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Make Public", isOn: $isPublic)
                        .font(.body)
                        .onChange(of: isPublic) { newValue in
                            editedBot.isPublic = newValue
                            if newValue.isFalse {
                                isOpenSource = false
                            }
                            checkForChanges()
                        }
                    Text("Everyone can use your bot")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Open Source", isOn: $isOpenSource)
                        .font(.body)
                        .onChange(of: isOpenSource) { newValue in
                            editedBot.isOpenSource = newValue
                            if newValue {
                                isPublic = true
                            }
                            checkForChanges()
                        }
                    Text("Everyone can see and copy your bot settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 6)
                }
            }
            
            Section(header: Text("AI Configuration").font(.subheadline)) {
                TextField("Image Caption Instructions", text: Binding(
                    get: { editedBot.caption ?? "" },
                    set: {
                        editedBot.caption = $0
                        checkForChanges()
                    }
                ))
                .font(.body)
                TextField("Prefix Instructions", text: Binding(
                    get: { editedBot.prefix ?? "" },
                    set: {
                        editedBot.prefix = $0
                        checkForChanges()
                    }
                ))
                .font(.body)
                TextField("Suffix Instructions", text: Binding(
                    get: { editedBot.suffix ?? "" },
                    set: {
                        editedBot.suffix = $0
                        checkForChanges()
                    }
                ))
                .font(.body)
                TextField("Welcome Message", text: Binding(
                    get: { editedBot.welcome ?? "" },
                    set: {
                        editedBot.welcome = $0
                        checkForChanges()
                    }
                ))
                .font(.body)
            }
            
            Section(header: Text("Image").font(.subheadline)) {
                // Image preview (if selected)
                if let selectedImage {
                    HStack {
                        Spacer()
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                        Spacer()
                    }
                    .padding(.vertical, 4)
                } else if let imageURL = editedBot.imageURL {
                    // Show existing image preview from URL if available
                    VStack {
                        HStack {
                            Spacer()
                            // Use ID modifier with counter to force refresh when URL changes
                            CachedImage(url: imageURL) { imageData in
                                if let image = UIImage(data: imageData) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                }
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 150, height: 150)
                            }
                            .id("cachedImage-\(imageURL.absoluteString)-\(urlUpdateCounter)")
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            Spacer()
                        }
                        Text("Image URL: \(imageURL.absoluteString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                } else {
                    // Show placeholder image when no image is selected
                    HStack {
                        Spacer()
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Image selection buttons
                HStack {
#if os(Android)
                    Spacer()
#endif
                    Button(action: {
                        pickerType = .library
                        showMediaPicker = true
                    }) {
                        HStack {
#if !os(Android)
                            Image(systemName: "photo")
#endif
                            Text("From Library")
                        }
                    }
                    .buttonStyle(.bordered)
#if os(Android)
                    Spacer()
#endif
                    Button(action: {
                        pickerType = .camera
                        showMediaPicker = true
                    }) {
                        HStack {
#if !os(Android)
                            Image(systemName: "camera")
#endif
                            Text("Take Photo")
                        }
                    }
                    .buttonStyle(.bordered)
#if os(Android)
                    Spacer()
#endif
                }
                .padding(.vertical, 4)
                
                // Manual URL entry (fallback option)
                TextField("Or enter image URL", text: $imageURLString)
#if !os(Android)
                    .disableAutocorrection(true)
#endif
                    .font(.body)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .onChange(of: imageURLString) { newValue in
                        // Cancel any previous task
                        imageURLDebounceTask?.cancel()
                        
                        // Don't try to process empty or very short URLs
                        if newValue.count < 10 {
                            // Clear image URL if text is too short
                            if editedBot.imageURL != nil {
                                editedBot.imageURL = nil
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
                            await MainActor.run {
                                if let imageURL = URL(string: newValue), imageURL.canOpen {
                                    let oldURL = editedBot.imageURL
                                    editedBot.imageURL = imageURL
                                    // Clear selected image if URL is provided manually
                                    selectedImage = nil
                                    selectedMediaURL = nil
                                    // Increment counter to force view update
                                    urlUpdateCounter += 1
                                    
                                    // Check if URL has changed from the original
                                    if oldURL != imageURL {
                                        checkForChanges()
                                    }
                                }
                            }
                        }
                    }
            }
            
            Section {
#if os(Android)
                HStack {
                    // Cancel button for Android
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                    }
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                    
                    // Update button
                    Button(action: updateAIBot) {
                        if isUpdating || isUploading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(editedBot.name.isEmptyTrimmed || !hasChanges || isUpdating || isUploading)
                    .font(.body)
                    .padding()
                    .background(
                        (editedBot.name.isEmptyTrimmed || !hasChanges || isUpdating || isUploading)
                        ? Color.gray.opacity(0.5)
                        : Color.blue
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
#else
                // Full width Update button for iOS (Cancel is in toolbar)
                Button(action: updateAIBot) {
                    if isUpdating || isUploading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Update")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(editedBot.name.isEmptyTrimmed || !hasChanges || isUpdating || isUploading)
                .font(.body)
                .padding()
                .background(
                    (editedBot.name.isEmptyTrimmed || !hasChanges || isUpdating || isUploading)
                    ? Color.gray.opacity(0.5)
                    : Color.blue
                )
                .foregroundColor(.white)
                .cornerRadius(10)
#endif
            }
            .listRowBackground(Color.clear)
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
            Text(errorMessage)
        }
        // MediaPicker from SkipKit
        .withMediaPicker(type: pickerType, isPresented: $showMediaPicker, selectedImageURL: $selectedMediaURL)
        .onChange(of: selectedMediaURL) { newURL in
            if let url = newURL {
                loadImageFromURL(url)
            }
        }
        .onDisappear {
            // Cancel any ongoing tasks when view disappears
            imageURLDebounceTask?.cancel()
            imageURLDebounceTask = nil
        }
#if !os(Android)
        // iOS toolbar
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
#endif
    }
}

private extension EditBotView {
    func checkForChanges() {
        // Check if any properties have changed from the original bot
        hasChanges = originalBot.name != editedBot.name
        || originalBot.desc != editedBot.desc
        || originalBot.isPublic != editedBot.isPublic
        || originalBot.isOpenSource != editedBot.isOpenSource
        || originalBot.caption != editedBot.caption
        || originalBot.prefix != editedBot.prefix
        || originalBot.suffix != editedBot.suffix
        || originalBot.welcome != editedBot.welcome
        || originalBot.imageURL != editedBot.imageURL
        || selectedImage != nil
    }
    
    func loadImageFromURL(_ url: URL) {
        // Load the selected image from the URL
        Task {
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        // Clear any manual URL input
                        imageURLString = ""
                        // Mark that changes have been made
                        checkForChanges()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func updateAIBot() {
        guard let user = authManager.user else {
            errorMessage = "You must be logged in to update an AI bot"
            showErrorAlert = true
            return
        }
        guard editedBot.name.notEmptyTrimmed else {
            errorMessage = "Please provide a name for your AI bot"
            showErrorAlert = true
            return
        }
        
        // Disable dismiss gestures during update
        isUpdating = true
        
        // Save the trimmed version to avoid empty strings
        var botToUpdate = editedBot.trimmed
        
        Task {
            do {
                // If there's a selected image, upload it first
                if selectedImage != nil, imageURLString.isEmptyTrimmed {
                    if let downloadURL = try await uploadImageToStorage() {
                        botToUpdate.imageURL = downloadURL
                    }
                } else if imageURLString.notEmptyTrimmed && editedBot.imageURL?.absoluteString != imageURLString {
                    botToUpdate.imageURL = URL(string: imageURLString)
                }
                
                // Update the AI setting in Firestore
                try await FirestoreManager.shared.updateAISetting(botToUpdate, userID: user.uid)
                
                // Using MainActor to update UI state
                await MainActor.run {
                    isUpdating = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isUpdating = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    func uploadImageToStorage() async throws -> URL? {
        guard let user = authManager.user, let image = selectedImage else { return nil }
        await MainActor.run {
            isUploading = true
        }
        do {
            let path = StorageManager.shared.generateUniqueFilePath(for: user.uid,
                                                                    fileType: "ai_settings",
                                                                    fileExtension: "jpg")
            let downloadURL = try await StorageManager.shared.uploadImage(image, to: path, compressionQuality: 0.75)
            await MainActor.run {
                isUploading = false
            }
            return downloadURL
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isUploading = false
                showErrorAlert = true
            }
            throw error
        }
    }
}
