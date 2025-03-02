// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  NeedToAuthorize.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/2/25.
//

import SwiftUI

struct NeedToAuthorize: View {
    @Binding var showAuthSheet: Bool
    var reason: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding()
            
            Text("Sign In Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(reason)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            Button("Sign In") {
                showAuthSheet = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
