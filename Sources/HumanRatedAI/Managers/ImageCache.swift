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
    private let cacheExpirationSeconds: TimeInterval = 60 // Shorter cache time to force refreshes
    private let directURLTimeout: TimeInterval = 15
    
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
        
        // Special handling for Firebase Storage URLs
        if url.absoluteString.contains("firebasestorage.googleapis.com") {
            do {
                // Use a more aggressive approach for Firebase Storage on iOS
#if !os(Android)
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = directURLTimeout
                config.requestCachePolicy = .reloadIgnoringLocalCacheData
                let session = URLSession(configuration: config)
                
                // Try with an additional parameter to force a fresh response
                let timestamp = Int(Date().timeIntervalSince1970)
                let freshURL = URL(string: url.absoluteString + "&fresh=\(timestamp)")!
                
                let (data, _) = try await session.data(from: freshURL)
                setImageData(data, for: url)
                return data
#endif
            } catch {
                debug("DIRECT", Self.self, "Firebase direct fetch failed: \(error)")
                // Fall through to standard approach
            }
        }
        
        // Standard download approach
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
    private let retryTrigger: Int
    private let onLoadFailure: () -> Void
    
    @State private var imageData: Data?
    @State private var isLoading = false
    @State private var loadTask: Task<Void, Never>?
    
    public init(url: URL?,
                retryTrigger: Int = 0,
                onLoadFailure: @escaping () -> Void = {},
                @ViewBuilder content: @escaping (Data) -> Content,
                @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.retryTrigger = retryTrigger
        self.onLoadFailure = onLoadFailure
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
        .onChange(of: retryTrigger) { _ in
            if retryTrigger > 0 {
                loadImage()
            }
        }
        .onDisappear {
            // Cancel the loading task when view disappears
            loadTask?.cancel()
            loadTask = nil
        }
    }
    
    private func loadImage() {
        guard !isLoading, let url = url else { return }
        
        isLoading = true
        
        // Cancel any existing task
        loadTask?.cancel()
        
        // Create a new task
        loadTask = Task {
            do {
                // For Firebase Storage URLs, add platform-specific optimizations
                if url.absoluteString.contains("firebasestorage.googleapis.com") {
                    // Try loading with a direct request and cache-busting parameter
                    let cacheBuster = Int(Date().timeIntervalSince1970 * 1000)
                    let urlWithCacheBusting = URL(string: url.absoluteString + "&cb=\(cacheBuster)")
                    
                    if let cacheBustingURL = urlWithCacheBusting {
                        do {
                            let sessionConfig = URLSessionConfiguration.default
                            sessionConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
                            sessionConfig.timeoutIntervalForRequest = 20
                            let session = URLSession(configuration: sessionConfig)
                            
                            let (data, response) = try await session.data(from: cacheBustingURL)
                            
                            if let httpResponse = response as? HTTPURLResponse,
                               (200...299).contains(httpResponse.statusCode),
                               !Task.isCancelled {
                                await MainActor.run {
                                    self.imageData = data
                                    self.isLoading = false
                                }
                                return
                            }
                        } catch {
                            debug("CACHE-BUSTING", "Failed with: \(error)")
                            // Continue to standard method if cache-busting fails
                        }
                    }
                }
                
                // Standard image loading through cache
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
                        self.onLoadFailure()
                    }
                }
            }
        }
    }
}

class ImageMemoryCache {
    static let shared = ImageMemoryCache()
    private var cache = [String: UIImage]()
    private let lock = NSLock()
    
    func getImage(for key: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        return cache[key]
    }
    
    func setImage(_ image: UIImage, for key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache[key] = image
    }
    
    func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
