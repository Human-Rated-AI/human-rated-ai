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

#if os(iOS)
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        
        // Add some debugging for WebView
        webView.navigationDelegate = context.coordinator
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            debug("ERROR", WebView.self, "WebView failed to load: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            debug("INFO", WebView.self, "WebView finished loading")
        }
    }
}
#else
// For Android/Skip - simple fallback
struct WebView: View {
    let url: URL
    
    var body: some View {
        VStack {
            Text("WebView not available on this platform")
            Text(url.absoluteString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif

// Custom image view that handles Firebase Storage URLs better
struct FirebaseImageView: View {
    let url: URL
    let maxWidth: CGFloat
    let maxHeight: CGFloat
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var retryCount = 0
    @State private var showModal = false
    
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
            loadImage()
        }
        .sheet(isPresented: $showModal) {
            GeometryReader { geometry in
                VStack {
                    Text(imageUploadTimeString)
                        .font(.headline)
                        .padding()
                    
                    if let image = image {
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: geometry.size.width - 40,
                                       maxHeight: geometry.size.height - 150)
                                .clipped()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack {
                            ProgressView()
                            Text("Loading image...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    Spacer()
                    
                    Button("Done") {
                        showModal = false
                    }
                    .padding()
                }
            }
            .navigationTitle("Image Viewer")
            .navigationBarTitleDisplayMode(.inline)
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
                    // Use Firebase SDK directly (same as AvatarView)
                    let image = try await StorageManager.shared.downloadImageFromURL(url)
                    
                    await MainActor.run {
                        self.image = image
                        self.isLoading = false
                        debug("INFO", FirebaseImageView.self, "Successfully loaded image via Firebase SDK")
                    }
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
                        maxHeight: 300
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
