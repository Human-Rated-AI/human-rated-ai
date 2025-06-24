// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  MessageInput.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 4/9/25.
//

import SwiftUI
import SkipKit

struct MessageInput: View {
    @Binding var messageText: String
    @Environment(\.colorScheme) private var colorScheme
    let onSend: () -> Void
    let onImageUpload: (() -> Void)?
    var isLoading: Bool = false
    
    // State for image picker
    @State private var showImagePicker = false
    @State private var selectedImageURL: URL?
    
    private var sendMessageIcon: String {
#if os(Android)
        "paperplane"
#else
        "paperplane.fill"
#endif
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Image upload button
            if !isLoading && onImageUpload != nil {
                Button(action: {
                    print("📷 Image upload button tapped")
                    showImagePicker = true
                }) {
#if os(Android)
                    Image("camera")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                        .padding(8)
#else
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .padding(8)
#endif
                }
            }
            
            TextField("Type a message...", text: $messageText)
                .padding(10)
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1))
                .cornerRadius(20)
                .onSubmit {
                    if !isLoading && !messageText.isEmptyTrimmed {
                        onSend()
                    }
                }
                .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .padding(8)
            } else {
                Button(action: onSend) {
#if os(Android)
                    Image(systemName: sendMessageIcon)
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(-45))
#else
                    Image(systemName: sendMessageIcon)
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
#endif
                }
                .disabled(messageText.isEmptyTrimmed)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(colorScheme == .dark ? Color.black : Color.white)
#if os(Android)
        .withMediaPicker(type: .library, isPresented: $showImagePicker, selectedImageURL: $selectedImageURL)
#else
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImageURL: $selectedImageURL)
        }
#endif
        .onChange(of: selectedImageURL) { imageURL in
            if let imageURL {
                print("📸 Image selected: \(imageURL)")
                onImageUpload?()
                // Reset the selected image URL for next time
                selectedImageURL = nil
            }
        }
    }
}
