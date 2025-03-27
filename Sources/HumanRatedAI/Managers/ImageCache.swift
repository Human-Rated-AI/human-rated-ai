// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ImageCache.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/19/25.
//

import Foundation
import SwiftUI

// Create a platform-agnostic image cache
public class ImageCache: ObservableObject {
    public static let shared = ImageCache()
    
    @Published private var cache: [URL: Data] = [:]
    
    private init() {}
    
    public func getImageData(for url: URL) -> Data? {
        return cache[url]
    }
    
    public func setImageData(_ data: Data, for url: URL) {
        cache[url] = data
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
}

// Create a reusable CachedImage view
public struct CachedImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let content: (Data) -> Content
    private let placeholder: () -> Placeholder
    
    @State private var imageData: Data?
    @State private var isLoading = false
    
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
    }
    
    private func loadImage() {
        guard let url = url, !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                let data = try await ImageCache.shared.loadImage(from: url)
                await MainActor.run {
                    self.imageData = data
                    self.isLoading = false
                }
            } catch {
                debug("FAIL", Self.self, "loading image: \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
