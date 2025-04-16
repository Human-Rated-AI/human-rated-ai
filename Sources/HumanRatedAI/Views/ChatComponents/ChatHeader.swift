// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ChatHeader.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 4/9/25.
//

import SwiftUI

struct ChatHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let botName: String
    
    var body: some View {
        HStack {
            Text(botName)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)
            Spacer()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        Divider()
    }
}
