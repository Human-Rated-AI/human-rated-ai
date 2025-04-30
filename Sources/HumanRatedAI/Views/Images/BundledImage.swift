// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org
//
//  BundledImage.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/13/25.
//

import SwiftUI

struct BundledImage: View {
    let name: String
    let ext: String
    let width: CGFloat?
    let height: CGFloat?
    
    init(_ name: String, withExtension ext: String = "", width: CGFloat? = nil, height: CGFloat? = nil) {
        self.name = name
        self.ext = ext
        self.width = width
        self.height = height
    }
    
    var body: some View {
#if os(Android)
        let path = "Module.xcassets/\(name).imageset/\(name)"
        let imageURL = Bundle.module.url(forResource: path, withExtension: ext)
        
        if let imageURL = imageURL {
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure(_):
                    // Fallback for failed image load
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.gray)
                @unknown default:
                    ProgressView()
                }
            }
            .frame(width: width, height: height)
        } else {
            // Fallback for missing image URL
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .foregroundColor(.gray)
                .frame(width: width, height: height)
                .onAppear {
                    debug("FAIL", BundledImage.self, "Failed to load bundled image: \(name)\(ext.isEmpty ? "" : "."+ext)")
                }
        }
#else
        Image(name, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
#endif
    }
}
