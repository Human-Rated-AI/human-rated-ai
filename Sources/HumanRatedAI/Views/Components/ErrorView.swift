// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  ErrorView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 5/3/25.
//

import SwiftUI

struct ErrorView: View {
    @Environment(\.colorScheme) private var colorScheme
    let errorMessage: String
    let errorTitle: String
    let tryAgainAction: (() -> Void)?
    
    init(_ title: String, message: String, tryAgainAction: (() -> Void)? = nil) {
        self.errorTitle = title
        self.errorMessage = message
        self.tryAgainAction = tryAgainAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            Text(errorTitle)
                .font(.title2)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if let tryAgainAction {
                Button("Try Again") {
                    tryAgainAction()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
    }
}
