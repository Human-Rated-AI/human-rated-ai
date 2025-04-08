// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ImageCache.swift
//  human-rated-ai
//
//  Created by Claude 3.7 Sonnet, Denis Bystruev on 3/19/25.
//

import Foundation
import SwiftUI

// Create a platform-agnostic image cache
public class ImageCache: ObservableObject {
    public static let shared = ImageCache()
    
    // Simple cache structure with expiration times
    private class CacheEntry {
        let data: Data
        let expirationTime: TimeInterval
        
        init(data: Data, expirationTime: TimeInterval) {
            self.data = data
            self.expirationTime = expirationTime
        }
        
        var isExpired: Bool {
            Date().timeIntervalSince1970 > expirationTime
        }
    }
    
    @Published private var cache = [String: CacheEntry]()
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    public func getImageData(for url: URL) -> Data? {
        let key = url.absoluteString
        
        // Clean expired cache entries when accessed
        removeExpiredEntries()
        
        guard let entry = cache[key], !entry.isExpired else {
            if cache[key] != nil {
                cache.removeValue(forKey: key)
            }
            return nil
        }
        
        return entry.data
    }
    
    public func setImageData(_ data: Data, for url: URL) {
        let key = url.absoluteString
        let expirationTime = Date().timeIntervalSince1970 + cacheExpirationSeconds
        cache[key] = CacheEntry(data: data, expirationTime: expirationTime)
    }
    
    public func loadImage(from url: URL) async throws -> Data {
        // Check cache first
        if let cachedData = getImageData(for: url) {
            return cachedData
        }
        
        // Otherwise download
        let (data, _) = try await URLSession.shared.data(from: url)
        setImageData(data, for: url)
        return data
    }
    
    public func clearCache() {
        cache.removeAll()
    }
    
    private func removeExpiredEntries() {
        for (key, entry) in cache {
            if entry.isExpired {
                cache.removeValue(forKey: key)
            }
        }
    }
}

// Create a reusable CachedImage view
public struct CachedImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Data) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?
    @State private var retryCount = 0
    private let maxRetries = 2
    
    public init(url: URL?,
                @ViewBuilder content: @escaping (Data) -> Content,
                @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    public var body: some View {
        Group {
            if let imageData = imageData {
                content(imageData)
            } else {
                placeholder()
                    .onAppear {
                        loadImage()
                    }
            }
        }
        .onDisappear {
            // Cancel the loading task when view disappears
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadImage() {
        guard !isLoading, retryCount <= maxRetries, let url = url else { return }
        
        isLoading = true
        
        // Cancel any existing task
        loadTask?.cancel()
        
        // Create a new task
        loadTask = Task {
            do {
                let data = try await ImageCache.shared.loadImage(from: url)
                
                // Check if task was cancelled before updating UI
                if !Task.isCancelled {
                    await MainActor.run {
                        self.imageData = data
                        self.isLoading = false
                    }
                }
            } catch {
                // Only process error if task wasn't cancelled
                if !Task.isCancelled {
                    debug("FAIL", Self.self, "Error loading image: \(error.localizedDescription)")
                    
                    await MainActor.run {
                        self.isLoading = false
                        self.retryCount += 1
                        
                        // Try again after a delay if we haven't hit max retries
                        if self.retryCount <= self.maxRetries {
                            DispatchQueue.main.asyncAfter(deadline: .now() + Double(self.retryCount)) {
                                self.loadImage()
                            }
                        }
                    }
                }
            }
        }
    }
}
