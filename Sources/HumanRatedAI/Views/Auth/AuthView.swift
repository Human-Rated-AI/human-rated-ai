// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AuthView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/2/25.
//

#if !os(Android)
import AuthenticationServices
#endif
import SwiftUI

struct AuthView: View {
    @Binding var showAuthSheet: Bool
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isLandscape: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .compact
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: CGFloat(isLandscape ? 15 : 20)) {
                if isLandscape {
                    WelcomeView(alignment: .leading)
                } else {
                    WelcomeView(alignment: .center)
                        .padding(.top, 30)
                }
                
                if authManager.isAuthenticating {
                    // Show progress
                    ProgressView()
                        .padding()
                }
                
                Spacer()
                
                // Social sign-in buttons
                if isLandscape {
                    HStack(spacing: 30) {
                        SignInButtons(showAuthSheet: $showAuthSheet)
                    }
                } else {
                    SignInButtons(showAuthSheet: $showAuthSheet)
                }
                
                if !authManager.errorMessage.isEmpty {
                    Spacer()
                    Text(authManager.errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                Button("Cancel") {
                    showAuthSheet = false
                }
                .disabled(authManager.isAuthenticating)
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                authManager.errorMessage = ""
            }
            
        }
    }
}

private struct SignInButtons: View {
    @Binding var showAuthSheet: Bool
    @EnvironmentObject var authManager: AuthManager
    
    // Social sign-in buttons
    var body: some View {
        // Apple button
#if os(Android)
        Button {
            authManager.signInWithApple() {
                showAuthSheet = false
            }
        } label: {
            BundledImage("Continue with Apple", withExtension: "pdf")
        }
        .frame(width: 300, height: 50)
        .disabled(authManager.isAuthenticating)
#else
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
            // Set the nonce for the sign-in request
            let nonce = authManager.startSignInWithApple()
            request.nonce = nonce.sha256 // Use SHA256 instead of MD5
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                authManager.handleSuccessfulLogin(with: authorization)
                showAuthSheet = false
            case .failure(let error):
                authManager.handleLoginError(with: error)
            }
        }
        .frame(width: 300, height: 50)
        .disabled(authManager.isAuthenticating)
#endif
        
        // Google button
        Button {
            authManager.signInWithGoogle() {
                showAuthSheet = false
            }
        } label: {
            BundledImage("Continue with Google", withExtension: "pdf")
        }
        .frame(width: 300, height: 50)
        .disabled(authManager.isAuthenticating)
    }
}

private struct WelcomeView: View {
    let alignment: Alignment
    
    var body: some View {
        // \u{00A0} is non-breaking space to keep Human Rated together
        Text("Welcome to Human\u{00A0}Rated AI")
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(alignment == .center ? .center : .leading)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}
