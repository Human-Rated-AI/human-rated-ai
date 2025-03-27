// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  CreateTabView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 10/27/24.
//

import SwiftUI

struct CreateTabView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var aiSetting = AISetting(name: "")
    @State private var errorMessage = ""
    @State private var isPublic = false
    @State private var isSaving = false
    @State private var imageURLString = ""
    @State private var showErrorAlert = false
    @State private var showSuccessAlert = false
    
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
#if !os(Android)
                                .foregroundColor(Color(.placeholderText))
                                .padding(.top, 8)
#else
                                .foregroundColor(Color.gray)
                                .opacity(0.67)
                                .padding(.leading, 12)
                                .padding(.top, 18)
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
                    
                    Toggle("Make Public", isOn: $isPublic)
                        .font(.body)
                        .onChange(of: isPublic) { newValue in
                            aiSetting.isPublic = newValue
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
                    TextField("Image URL", text: $imageURLString)
                        .font(.body)
                        .onChange(of: imageURLString) { newValue in
                            aiSetting.imageURL = URL(string: newValue)
                        }
                }
                
                Section {
                    Button(action: saveAIBot) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create AI Bot")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(aiSetting.name.isEmptyTrimmed || isSaving)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(aiSetting.name.isEmptyTrimmed ? Color.gray.opacity(0.5) : Color.blue)
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
                Text("Your AI Bot has been created successfully!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

private extension CreateTabView {
    func resetForm() {
        aiSetting = AISetting(name: "")
        imageURLString = ""
        isPublic = false
    }
    
    func saveAIBot() {
        guard let user = authManager.user else {
            errorMessage = "You must be logged in to create an AI Bot"
            showErrorAlert = true
            return
        }
        guard aiSetting.name.isNotEmptyTrimmed else {
            errorMessage = "Please provide a name for your AI Bot"
            showErrorAlert = true
            return
        }
        isSaving = true
        aiSetting.id = UUID().uuidString
        Task {
            do {
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
}
