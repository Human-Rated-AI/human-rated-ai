// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  MessageBubble.swift
//  human-rated-ai
//
//  Created by Claude 3.7 Sonet, Denis Bystruev on 4/8/25.
//

import SwiftUI

// Custom image view that handles Firebase Storage URLs better
struct FirebaseImageView: View {
    @Environment(\.colorScheme) private var colorScheme
    let url: URL
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var retryCount = 0
    @State private var showModal = false
    @State private var extractedTimeString = "Image Preview"
    
    // Extract upload time from Firebase URL
    private var imageUploadTimeString: String {
        let urlString = url.absoluteString
        
        // First decode URL encoding (%2F becomes /)
        let decodedString = urlString.replacingOccurrences(of: "%2F", with: "/")
        
        // Extract timestamp from filename pattern: timestamp_uuid_random.jpg
        // Split by '/' and look for the filename component
        let urlComponents = decodedString.components(separatedBy: "/")
        
        for component in urlComponents {
            // Look for components that start with a timestamp pattern
            if component.contains("_") {
                let parts = component.components(separatedBy: "_")
                if parts.count >= 3, let timestamp = Double(parts[0]) {
                    let date = Date(timeIntervalSince1970: timestamp)
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    return "Uploaded \(formatter.string(from: date))"
                }
            }
        }
        
        // Fallback
        return "Image Preview"
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .onTapGesture {
                        showModal = true
                    }
            } else if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("Loading image...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    if retryCount < 3 {
                        Button("Retry") {
                            retryCount += 1
                            loadImage()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    } else {
                        Text("Failed to load image")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Button("View in Browser") {
                        showModal = true
                    }
                    .font(.caption)
                    .foregroundColor(.green)
                }
                .onTapGesture {
                    showModal = true
                }
            }
        }
        .frame(maxWidth: maxWidth, maxHeight: maxHeight)
        .onAppear {
            extractedTimeString = imageUploadTimeString
            loadImage()
        }
        .sheet(isPresented: $showModal) {
            VStack(spacing: 16) {
                // Title - use the extracted timestamp with proper color scheme support
                Text(extractedTimeString)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top)
                
                // Image display
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 300, maxHeight: 400)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Loading image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 200, height: 200)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Done button
                Button("Done") {
                    showModal = false
                }
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom)
            }
            .padding(.horizontal, 20)
            .background(colorScheme == .dark ? Color.black : Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func loadImage() {
        isLoading = true
        error = nil
        
        Task {
            do {
                debug("INFO", FirebaseImageView.self, "Loading image from: \(url)")
                
                // Use the same method as AvatarView for Firebase Storage URLs
                if url.absoluteString.contains("firebasestorage.googleapis.com") {
                    #if os(Android)
                    // For Android: Use URLSession for public chat images to avoid auth issues
                    if url.absoluteString.contains("public%2Fchat_images") || url.absoluteString.contains("public/chat_images") {
                        // Use URLSession for public images
                        var request = URLRequest(url: url)
                        request.timeoutInterval = 30.0
                        request.cachePolicy = .reloadIgnoringLocalCacheData
                        
                        let (data, response) = try await URLSession.shared.data(for: request)
                        
                        if let httpResponse = response as? HTTPURLResponse {
                            debug("INFO", FirebaseImageView.self, "HTTP Response: \(httpResponse.statusCode)")
                        }
                        
                        guard let uiImage = UIImage(data: data) else {
                            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create image from data"])
                        }
                        
                        await MainActor.run {
                            self.image = uiImage
                            self.isLoading = false
                            debug("INFO", FirebaseImageView.self, "Successfully loaded public image via URLSession")
                        }
                    } else {
                        // Use Firebase SDK for authenticated images (like avatars)
                        let image = try await StorageManager.shared.downloadImageFromURL(url)
                        
                        await MainActor.run {
                            self.image = image
                            self.isLoading = false
                            debug("INFO", FirebaseImageView.self, "Successfully loaded image via Firebase SDK")
                        }
                    }
                    #else
                    // For iOS: Use Firebase SDK directly (same as AvatarView) - this was working before
                    let image = try await StorageManager.shared.downloadImageFromURL(url)
                    
                    await MainActor.run {
                        self.image = image
                        self.isLoading = false
                        debug("INFO", FirebaseImageView.self, "Successfully loaded image via Firebase SDK")
                    }
                    #endif
                } else {
                    // For non-Firebase URLs, use URLSession
                    var request = URLRequest(url: url)
                    request.timeoutInterval = 30.0
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        debug("INFO", FirebaseImageView.self, "HTTP Response: \(httpResponse.statusCode)")
                    }
                    
                    guard let uiImage = UIImage(data: data) else {
                        throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create image from data"])
                    }
                    
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                        debug("INFO", FirebaseImageView.self, "Successfully loaded image via URLSession")
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    debug("ERROR", FirebaseImageView.self, "Failed to load image (attempt \(retryCount + 1)): \(error.localizedDescription)")
                }
            }
        }
    }
}

struct MessageBubble: View {
    @Environment(\.colorScheme) private var colorScheme
    let message: Message
    let botImageURL: URL?
    let maxWidth: CGFloat
    
    // Calculate effective max width accounting for avatar space
    private var effectiveMaxWidth: CGFloat {
        // Account for avatar width (32) + spacing (8)
        return max(maxWidth - 40, maxWidth * 0.7)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            } else {
                // Bot avatar
                AvatarView(imageURL: botImageURL, width: 32, height: 32)
            }
            
            // Message bubble
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Display image if present
                if let imageURL = message.imageURL {
                    FirebaseImageView(
                        url: imageURL,
                        maxWidth: effectiveMaxWidth,
                        maxHeight: 300.0
                    )
                    .cornerRadius(12)
                }
                
                // Display text if present
                if !message.content.isEmpty {
                    Text(message.content)
                        .padding(12)
                        .background(message.isUser ? Color.blue : (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.1)))
                        .foregroundColor(message.isUser ? .white : (colorScheme == .dark ? .white : .black))
                        .cornerRadius(16)
                }
            }
            .frame(maxWidth: effectiveMaxWidth, alignment: message.isUser ? .trailing : .leading)
            
            if message.isUser {
                // User avatar (placeholder - this would use user's avatar in a real implementation)
                let userAvatarURL: URL? = nil // Replace with actual user avatar URL
                AvatarView(imageURL: userAvatarURL, width: 32, height: 32)
            } else {
                Spacer()
            }
        }
    }
}
