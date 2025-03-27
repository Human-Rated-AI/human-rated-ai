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
    @State private var aiSetting = AISetting(creatorID: 0, name: "")
    @State private var imageURLString: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information").font(.subheadline)) {
                    TextField("Name", text: $aiSetting.name)
                        .font(.body)
                    ZStack(alignment: .topLeading) {
                        if aiSetting.desc?.isEmpty != false {
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
                            set: { aiSetting.desc = $0.isEmpty ? nil : $0 }
                        ))
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, -4)
                        .frame(height: 100)
                    }
                }
                
                Section(header: Text("AI Configuration").font(.subheadline)) {
                    TextField("Image Caption Instructions", text: Binding(
                        get: { aiSetting.caption ?? "" },
                        set: { aiSetting.caption = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.body)
                    TextField("Prefix Instructions", text: Binding(
                        get: { aiSetting.prefix ?? "" },
                        set: { aiSetting.prefix = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.body)
                    TextField("Suffix Instructions", text: Binding(
                        get: { aiSetting.suffix ?? "" },
                        set: { aiSetting.suffix = $0.isEmpty ? nil : $0 }
                    ))
                    .font(.body)
                    TextField("Welcome Message", text: Binding(
                        get: { aiSetting.welcome ?? "" },
                        set: { aiSetting.welcome = $0.isEmpty ? nil : $0 }
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
                
                Button("Create AI Bot") {
                    // TODO: Implement create action
                    debug("DEBUG", "Creating AI Bot with settings: \(aiSetting)")
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Create AI Bot")
        }
    }
}
