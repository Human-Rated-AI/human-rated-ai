// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AvatarView.swift
//  human-rated-ai
//
//  Created by Claude 3.7 Sonet, Denis Bystruev on 4/8/25.
//

import SwiftUI

struct AvatarView: View {
    let imageURL: URL?
    let fallbackImageName: String = "person.crop.circle.fill"
    let width: CGFloat
    let height: CGFloat
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var loadFailed = false
    @State private var retryCount = 0
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
            } else if isLoading {
                ProgressView()
                    .frame(width: width, height: height)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: width, height: height)
                    
                    Button(action: {
                        retryCount += 1
                        isLoading = true
                        loadFailed = false
                        loadImage()
                    }) {
                        Image(systemName: "arrow.clockwise.circle")
                            .font(.system(size: width/4))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL else {
            isLoading = false
            return
        }
        
        // Check in-memory cache first
        let cacheKey = imageURL.absoluteString
        if let cachedImage = ImageMemoryCache.shared.getImage(for: cacheKey) {
            self.image = cachedImage
            self.isLoading = false
            return
        }
        
        if imageURL.absoluteString.contains("firebasestorage.googleapis.com") {
#if !os(Android)
            // For Firebase Storage URLs on iOS
            Task {
                do {
                    let image = try await StorageManager.shared.downloadImageFromURL(imageURL)
                    await MainActor.run {
                        // Save to cache before setting state
                        ImageMemoryCache.shared.setImage(image, for: cacheKey)
                        self.image = image
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.loadFailed = true
                        debug("FAIL", Self.self, "Failed to download: \(error.localizedDescription)")
                    }
                }
            }
#else
            // For Android, use URL approach with explicit error handling
            Task {
                do {
                    // Try to get from data cache first before network request
                    if let cachedData = ImageCache.shared.getImageData(for: imageURL),
                       let uiImage = UIImage(data: cachedData) {
                        await MainActor.run {
                            ImageMemoryCache.shared.setImage(uiImage, for: cacheKey)
                            self.image = uiImage
                            self.isLoading = false
                        }
                        return
                    }
                    
                    let data = try await ImageCache.shared.loadImage(from: imageURL)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            ImageMemoryCache.shared.setImage(uiImage, for: cacheKey)
                            self.image = uiImage
                            self.isLoading = false
                        }
                    } else {
                        throw NSError(domain: "AvatarView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.loadFailed = true
                        debug("FAIL", AvatarView.self, "Failed to download: \(error.localizedDescription)")
                    }
                }
            }
#endif
        } else {
            // For regular URLs
            loadImageFromURL(imageURL)
        }
    }
    
    private func loadImageFromURL(_ url: URL) {
        let cacheKey = url.absoluteString
        
        Task {
            do {
                // Try to get from data cache first
                if let cachedData = ImageCache.shared.getImageData(for: url),
                   let uiImage = UIImage(data: cachedData) {
                    await MainActor.run {
                        ImageMemoryCache.shared.setImage(uiImage, for: cacheKey)
                        self.image = uiImage
                        self.isLoading = false
                    }
                    return
                }
                
                // Otherwise download
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                
                let (data, _) = try await URLSession.shared.data(for: request)
                
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        // Save to both caches
                        ImageCache.shared.setImageData(data, for: url)
                        ImageMemoryCache.shared.setImage(uiImage, for: cacheKey)
                        self.image = uiImage
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                        self.loadFailed = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadFailed = true
                    debug("FAIL", AvatarView.self, "Failed to download: \(error.localizedDescription)")
                }
            }
        }
    }
}
