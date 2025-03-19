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
        AsyncImage(url: Bundle.module.url(forResource: path, withExtension: ext)) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(width: width, height: height)
#else
        Image(name, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
#endif
    }
}
