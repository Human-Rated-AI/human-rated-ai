// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AuthManager.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/2/25.
//

#if os(Android)
import SkipFirebaseAuth
#else
import AuthenticationServices
import FirebaseAuth
#endif
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String = ""
    @Published var user: User?
    
    static let shared = AuthManager()
    
    private init() {
#if !os(Android)
        // Listen for authentication state changes
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, authUser in
            DispatchQueue.main.async {
                self?.isAuthenticated = authUser != nil
                self?.user = authUser != nil ? User(displayName: authUser!.displayName,
                                                    email: authUser!.email,
                                                    uid: authUser!.uid
                ) : nil
            }
        }
#endif
    }
    
    struct User: Identifiable {
        let displayName: String?
        let email: String?
        let id = UUID()
        let uid: String
        
        init(displayName: String?, email: String?, uid: String?) {
            self.displayName = displayName?.trimmed
            self.email = email?.trimmed
            self.uid = uid?.nonEmptyTrimmed ?? id.uuidString
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.user = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func signInWithApple() {
        isAuthenticating = true
        errorMessage = ""
        
#if os(Android)
        // Android implementation
        // Use Google Sign-In as fallback on Android
        signInWithGoogle()
#else
        // iOS implementation using Apple Sign In
        let provider = OAuthProvider(providerID: "apple.com")
        provider.getCredentialWith(nil) { credential, error in
            if let error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticating = false
                }
                return
            }
            
            if let credential {
                Auth.auth().signIn(with: credential) { _, error in
                    DispatchQueue.main.async {
                        self.isAuthenticating = false
                        if let error {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Could not get credentials"
                    self.isAuthenticating = false
                }
            }
        }
#endif
    }
    
    func signInWithGoogle() {
        isAuthenticating = true
        errorMessage = ""
        
#if os(Android)
        // Android implementation
        Task { @MainActor in
            isAuthenticating = false
            errorMessage = "Not implemented"
        }
#else
        // iOS implementation
        let credential = GoogleAuthProvider.credential(withIDToken: "", accessToken: "")
        Auth.auth().signIn(with: credential) { authResult, error in
            DispatchQueue.main.async {
                self.isAuthenticating = false
                if let error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
#endif
    }
}

extension AuthManager {
#if !os(Android)
    func handleSuccessfulLogin(with authorization: ASAuthorization) {
        let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential
        let displayName = userCredential?.fullName?.formatted()
        handleSuccessfulLogin(displayName: displayName, email: userCredential?.email, uid: userCredential?.user)
    }
#endif
    
    func handleSuccessfulLogin(displayName: String?, email: String?, uid: String?) {
        errorMessage = ""
        isAuthenticated = true
        isAuthenticating = false
        user = User(displayName: displayName, email: email, uid: uid)
    }
    
    func handleLoginError(with error: Error) {
        errorMessage = error.localizedDescription
        isAuthenticated = false
        isAuthenticating = false
        user = nil
    }
}
