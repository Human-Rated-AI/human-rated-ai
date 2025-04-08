// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AISettingFormView.swift
//  human-rated-ai
//
//  Created by Claude on 4/3/25.
//

import SkipKit
import SwiftUI

// Protocol to define what a view model for AI Setting editing should implement
protocol AISettingViewModel: ObservableObject {
    var aiSetting: AISetting { get set }
    var errorMessage: String { get set }
    var hasChanges: Bool { get }
    var imageURLString: String { get set }
    var isActionInProgress: Bool { get }
    var isOpenSource: Bool { get set }
    var isPublic: Bool { get set }
    var isUploading: Bool { get }
    var selectedImage: UIImage? { get set }
    var selectedMediaURL: URL? { get set }
    var urlUpdateCounter: Int { get }
    
    func checkForChanges()
    func processImageURLString(_ newValue: String)
}

// MARK: - Main Form View
struct AISettingFormView<ViewModel: AISettingViewModel>: View {
    @ObservedObject var viewModel: ViewModel
    let action: () -> Void
    let actionLabel: String
    let isEdit: Bool
    let showBottomButton: Bool
    
    @State private var showMediaPicker = false
    @State private var pickerType: MediaPickerType = .library
    
    var body: some View {
        Form {
            // Basic Information Section
            Section(header: Text("Basic Information").font(.subheadline)) {
                basicInfoSection
            }
            
            // AI Configuration Section
            Section(header: Text("AI Configuration").font(.subheadline)) {
                aiConfigSection
            }
            
            // Image Section
            Section(header: Text("Image").font(.subheadline)) {
                imageSection
            }
            
            // Action Button (Create/Update) - Optional, can be hidden when using toolbar button
            if showBottomButton {
                Section {
                    actionButton
                }
                .listRowBackground(Color.clear)
            }
        }
        // MediaPicker integration
        .withMediaPicker(type: pickerType, isPresented: $showMediaPicker, selectedImageURL: $viewModel.selectedMediaURL)
        .onChange(of: viewModel.selectedMediaURL) { newURL in
            if let url = newURL {
                loadImageFromURL(url)
            }
        }
    }
    
    // Basic Information Section
    private var basicInfoSection: some View {
        Group {
            TextField("Name", text: Binding(
                get: { viewModel.aiSetting.name },
                set: {
                    viewModel.aiSetting.name = $0
                    viewModel.checkForChanges()
                }
            ))
            .font(.body)
            
            ZStack(alignment: .topLeading) {
                if viewModel.aiSetting.desc?.isEmptyTrimmed != false {
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
                    get: { viewModel.aiSetting.desc ?? "" },
                    set: {
                        viewModel.aiSetting.desc = $0
                        viewModel.checkForChanges()
                    }
                ))
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, -4)
                .frame(height: 100)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Make Public", isOn: Binding(
                    get: { viewModel.isPublic },
                    set: { newValue in
                        viewModel.isPublic = newValue
                        viewModel.aiSetting.isPublic = newValue
                        if newValue.isFalse {
                            viewModel.isOpenSource = false
                            viewModel.aiSetting.isOpenSource = false
                        }
                        viewModel.checkForChanges()
                    }
                ))
                .font(.body)
                
                Text("Everyone can use your bot")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 6)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Open Source", isOn: Binding(
                    get: { viewModel.isOpenSource },
                    set: { newValue in
                        viewModel.isOpenSource = newValue
                        viewModel.aiSetting.isOpenSource = newValue
                        if newValue {
                            viewModel.isPublic = true
                            viewModel.aiSetting.isPublic = true
                        }
                        viewModel.checkForChanges()
                    }
                ))
                .font(.body)
                
                Text("Everyone can see and copy your bot settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 6)
            }
        }
    }
    
    // AI Configuration Section
    private var aiConfigSection: some View {
        Group {
            TextField("Image Caption Instructions", text: Binding(
                get: { viewModel.aiSetting.caption ?? "" },
                set: {
                    viewModel.aiSetting.caption = $0
                    viewModel.checkForChanges()
                }
            ))
            .font(.body)
            
            TextField("Prefix Instructions", text: Binding(
                get: { viewModel.aiSetting.prefix ?? "" },
                set: {
                    viewModel.aiSetting.prefix = $0
                    viewModel.checkForChanges()
                }
            ))
            .font(.body)
            
            TextField("Suffix Instructions", text: Binding(
                get: { viewModel.aiSetting.suffix ?? "" },
                set: {
                    viewModel.aiSetting.suffix = $0
                    viewModel.checkForChanges()
                }
            ))
            .font(.body)
            
            TextField("Welcome Message", text: Binding(
                get: { viewModel.aiSetting.welcome ?? "" },
                set: {
                    viewModel.aiSetting.welcome = $0
                    viewModel.checkForChanges()
                }
            ))
            .font(.body)
        }
    }
    
    // Image Section
    private var imageSection: some View {
        Group {
            // Image preview
            if let selectedImage = viewModel.selectedImage {
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
            } else {
                // Show placeholder image when no image is selected
                HStack {
                    Spacer()
                    let imageURL = viewModel.aiSetting.imageURL
                    AvatarView(imageURL: imageURL, width: 150, height: 150)
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
            
            // Manual URL entry
            TextField("Or enter image URL", text: Binding(
                get: { viewModel.imageURLString },
                set: { viewModel.processImageURLString($0) }
            ))
#if !os(Android)
            .disableAutocorrection(true)
#endif
            .font(.body)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
        }
    }
    
    // Action Button (Create/Update)
    private var actionButton: some View {
        Button(action: action) {
            if viewModel.isActionInProgress || viewModel.isUploading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text(actionLabel)
                    .frame(maxWidth: .infinity)
            }
        }
        .disabled(viewModel.aiSetting.name.isEmptyTrimmed ||
                  (isEdit && !viewModel.hasChanges) ||
                  viewModel.isActionInProgress ||
                  viewModel.isUploading)
        .font(.body)
        .padding()
        .background(
            (viewModel.aiSetting.name.isEmptyTrimmed ||
             (isEdit && !viewModel.hasChanges) ||
             viewModel.isActionInProgress ||
             viewModel.isUploading)
            ? Color.gray.opacity(0.5)
            : Color.blue
        )
        .foregroundColor(.white)
        .cornerRadius(10)
    }
    
    // Load image from URL helper
    private func loadImageFromURL(_ url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        viewModel.selectedImage = image
                        viewModel.imageURLString = ""
                        viewModel.checkForChanges()
                    }
                }
            } catch {
                await MainActor.run {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Toolbar Update Button
struct AISettingToolbarButton<ViewModel: AISettingViewModel>: View {
    @ObservedObject var viewModel: ViewModel
    let action: () -> Void
    let isEdit: Bool
    
    var body: some View {
        Button(action: action) {
            if viewModel.isActionInProgress || viewModel.isUploading {
                ProgressView()
                    .frame(width: 16, height: 16)
            } else {
                Text(isEdit ? "Update" : "Create")
                    .fontWeight(.semibold)
            }
        }
        .disabled(viewModel.aiSetting.name.isEmptyTrimmed ||
                  (isEdit && !viewModel.hasChanges) ||
                  viewModel.isActionInProgress ||
                  viewModel.isUploading)
#if os(Android)
        // Android needs explicit styling
        .opacity(viewModel.aiSetting.name.isEmptyTrimmed || (isEdit && !viewModel.hasChanges) ? 0.5 : 1.0)
        .foregroundColor((!viewModel.aiSetting.name.isEmptyTrimmed && (!isEdit || viewModel.hasChanges)) &&
                         !viewModel.isActionInProgress &&
                         !viewModel.isUploading ? .blue : .gray)
#endif
    }
}
