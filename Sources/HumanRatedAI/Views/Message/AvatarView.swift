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
    let fallbackImageName: String
    
    @State private var imageData: Data? = nil
    
    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } else {
                Image(systemName: fallbackImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let imageURL else { return }
        
        Task {
            do {
                let data = try await StorageManager.shared.downloadData(from: imageURL.path)
                await MainActor.run {
                    self.imageData = data
                }
            } catch {
                debug("FAIL", AvatarView.self, "to load image: \(error)")
            }
        }
    }
}
