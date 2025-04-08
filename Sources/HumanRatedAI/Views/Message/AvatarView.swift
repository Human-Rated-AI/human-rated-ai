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
    
    var body: some View {
        if let imageURL {
            CachedImage(url: imageURL) { imageData in
                if let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
            } placeholder: {
                ProgressView()
                    .frame(width: width, height: height)
            }
            .frame(width: width, height: height)
            .clipShape(Circle())
        } else {
            Image(systemName: fallbackImageName)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
                .foregroundColor(.gray)
        }
    }
}
