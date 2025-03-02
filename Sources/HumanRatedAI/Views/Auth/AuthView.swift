// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AuthView.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/2/25.
//

#if !SKIP
import AuthenticationServices
#endif
import SwiftUI

struct AuthView: View {
    @Binding var showAuthSheet: Bool
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 30)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if authManager.isAuthenticating {
                    // Show progress
                    ProgressView()
                        .padding()
                }
                
                Spacer()
                
                // Social sign-in buttons
                VStack(spacing: 15) {
#if !SKIP
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            authManager.handleSuccessfulLogin(with: authorization)
                            showAuthSheet = false
                        case .failure(let error):
                            authManager.handleLoginError(with: error)
                        }
                    }
                    .frame(height: 50)
                    .padding()
                    .disabled(authManager.isAuthenticating)
#endif
                    
                    Button(action: {
                        authManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.headline)
                            Text("Continue with Google")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
#if SKIP
                        .background(Color.gray)
                        .opacity(0.67)
#else
                        .background(Color(.systemGray6))
#endif
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isAuthenticating)
                }
                .padding(.horizontal)
                
                if !authManager.errorMessage.isEmpty {
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
