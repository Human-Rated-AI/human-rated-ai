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

struct CreateTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var aiSetting = AISetting(name: "")
    @State private var errorMessage = ""
    @State private var isOpenSource = false
    @State private var isPublic = false
    @State private var isSaving = false
    @State private var imageURLString = ""
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
    // Media picker states
    @State private var isUploading = false
    @State private var selectedImage: UIImage?
    @State private var selectedMediaURL: URL?
    @State private var showMediaPicker = false
    @State private var pickerType: MediaPickerType = .library
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information").font(.subheadline)) {
                    TextField("Name", text: Binding(
                        get: { aiSetting.name },
                        set: { aiSetting.name = $0 }
                    ))
                    .font(.body)
                    ZStack(alignment: .topLeading) {
                        if aiSetting.desc?.isEmptyTrimmed != false {
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
                            get: { aiSetting.desc ?? "" },
                            set: { aiSetting.desc = $0 }
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
                                aiSetting.isPublic = newValue
                                if newValue.isFalse {
                                    isOpenSource = false
                                }
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
                                aiSetting.isOpenSource = newValue
                                if newValue {
                                    isPublic = true
                                }
                            }
                        Text("Everyone can see and copy your bot settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 6)
                    }
                }
                
                Section(header: Text("AI Configuration").font(.subheadline)) {
                    TextField("Image Caption Instructions", text: Binding(
                        get: { aiSetting.caption ?? "" },
                        set: { aiSetting.caption = $0 }
                    ))
                    .font(.body)
                    TextField("Prefix Instructions", text: Binding(
                        get: { aiSetting.prefix ?? "" },
                        set: { aiSetting.prefix = $0 }
                    ))
                    .font(.body)
                    TextField("Suffix Instructions", text: Binding(
                        get: { aiSetting.suffix ?? "" },
                        set: { aiSetting.suffix = $0 }
                    ))
                    .font(.body)
                    TextField("Welcome Message", text: Binding(
                        get: { aiSetting.welcome ?? "" },
                        set: { aiSetting.welcome = $0 }
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
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else if let imageURL = aiSetting.imageURL {
                        // Show existing image preview from URL if available
                        Text("Image URL: \(imageURL.absoluteString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
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
                        .font(.body)
                        .onChange(of: imageURLString) { newValue in
                            if newValue.notEmptyTrimmed {
                                aiSetting.imageURL = URL(string: newValue)
                                // Clear selected image if URL is provided manually
                                selectedImage = nil
                                selectedMediaURL = nil
                            }
                        }
                }
                
                Section {
                    Button(action: saveAIBot) {
                        if isSaving || isUploading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create AI Bot")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(aiSetting.name.isEmptyTrimmed || isSaving || isUploading)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(aiSetting.name.isEmptyTrimmed || isSaving || isUploading ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Create AI Bot")
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    resetForm()
                }
            } message: {
                Text("Your AI bot has been created successfully!")
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
        }
    }
}

private extension CreateTabView {
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
    
    func resetForm() {
        aiSetting = AISetting(name: "")
        imageURLString = ""
        isOpenSource = false
        isPublic = false
        selectedImage = nil
        selectedMediaURL = nil
    }
    
    func saveAIBot() {
        guard let user = authManager.user else {
            errorMessage = "You must be logged in to create an AI bot"
            showErrorAlert = true
            return
        }
        guard aiSetting.name.notEmptyTrimmed else {
            errorMessage = "Please provide a name for your AI bot"
            showErrorAlert = true
            return
        }
        isSaving = true
        aiSetting.id = UUID().uuidString
        Task {
            do {
                // If there's a selected image, upload it first
                if let selectedImage, imageURLString.isEmptyTrimmed {
                    if let downloadURL = try await uploadImageToStorage() {
                        aiSetting.imageURL = downloadURL
                    }
                } else if imageURLString.notEmptyTrimmed {
                    aiSetting.imageURL = URL(string: imageURLString)
                }
                
                // Save the AI setting to Firestore
                let documentID = try await FirestoreManager.shared.saveAISetting(aiSetting, userID: user.uid)
                await MainActor.run {
                    aiSetting.id = documentID
                    isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
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
            let path = StorageManager.shared.generateUniqueFilePath(for: user.uid, fileType: "ai_settings", fileExtension: "jpg")
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
