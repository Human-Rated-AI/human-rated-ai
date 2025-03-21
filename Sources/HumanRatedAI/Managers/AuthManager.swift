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
import SkipFirebaseFirestore
#else
import AuthenticationServices
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
#endif
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String = ""
    @Published var user: User?
    
    /// Current nonce for Apple Sign In
    private var currentNonce: String?
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
        // iOS implementation should use SignInWithAppleButton
        handleLoginError("Should be implemeted on iOS using SignInWithAppleButton")
#endif
    }
    
    func signInWithGoogle(completion: (() -> Void)? = nil) {
        isAuthenticating = true
        errorMessage = ""
        
#if os(Android)
        // Android implementation
        Task { @MainActor in
            handleLoginError("Not implemented")
        }
#else
        // iOS implementation
        // Get Google Sign In configuration
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            DispatchQueue.main.async {
                self.handleLoginError("Firebase configuration error")
            }
            return
        }
        
        // Create Google Sign In configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            DispatchQueue.main.async {
                self.handleLoginError("No root view controller found")
            }
            return
        }
        
        // Sign in with Google
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            guard let self else { return }
            
            DispatchQueue.main.async {
                if let error {
                    self.handleLoginError(with: error)
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    self.handleLoginError("Failed to get user data from Google")
                    return
                }
                
                // Create Firebase credential with Google ID token
                let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                               accessToken: user.accessToken.tokenString)
                
                // Sign in with Firebase
                Auth.auth().signIn(with: credential) { authResult, error in
                    DispatchQueue.main.async {
                        self.isAuthenticating = false
                        if let error {
                            self.handleLoginError(with: error)
                        } else if let authResult {
                            // Save user information
                            self.handleSuccessfulLogin(displayName: authResult.user.displayName,
                                                       email: authResult.user.email,
                                                       uid: authResult.user.uid)
                            
                            // Call completion handler if provided
                            completion?()
                        } else {
                            self.handleLoginError("Unknown error occurred while signing in")
                        }
                    }
                }
            }
        }
#endif
    }
}

extension AuthManager {
#if !os(Android)
    func handleSuccessfulLogin(with authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8),
              let nonce = currentNonce else {
            handleLoginError("Failed to get Apple identity token or nonce")
            return
        }
        
        // Create Firebase credential with Apple ID token
        let credential = OAuthProvider.credential(providerID: .apple,
                                                  idToken: tokenString,
                                                  rawNonce: nonce)
        
        // Sign in with Firebase
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isAuthenticating = false
                if let error {
                    self.handleLoginError(with: error)
                } else if let authResult {
                    let firebaseUser = authResult.user
                    
                    // Check if we need to update the profile (first-time login)
                    let displayName = appleIDCredential.fullName?.formatted()
                    let email = appleIDCredential.email
                    
                    // If we have name/email from Apple and Firebase profile is empty, update it
                    if (displayName != nil || email != nil) &&
                        (firebaseUser.displayName == nil || firebaseUser.displayName?.isEmpty == true) {
                        
                        let changeRequest = firebaseUser.createProfileChangeRequest()
                        if let displayName {
                            changeRequest.displayName = displayName
                        }
                        
                        changeRequest.commitChanges { [weak self] error in
                            if let error {
                                print("FAIL", #line, Self.self, #function,
                                      "Failed to update user profile: \(error.localizedDescription)")
                            }
                            // Save user information in the app
                            self?.handleSuccessfulLogin(displayName: firebaseUser.displayName,
                                                        email: firebaseUser.email ?? email,
                                                        uid: firebaseUser.uid)
                        }
                    } else {
                        // Handle the login
                        self.handleSuccessfulLogin(displayName: firebaseUser.displayName ?? displayName,
                                                   email: firebaseUser.email ?? email,
                                                   uid: firebaseUser.uid)
                    }
                } else {
                    self.handleLoginError("Unknown error occurred while signing in")
                }
            }
        }
        
        // Clear the stored nonce
        currentNonce = nil
    }
#endif
    
    func handleSuccessfulLogin(displayName: String?, email: String?, uid: String) {
        errorMessage = ""
        isAuthenticated = true
        isAuthenticating = false
        user = User(displayName: displayName, email: email, uid: uid)
        // Update Firestore document
        updateUserInFirestore(uid: uid, displayName: displayName, email: email)
    }
    
    func handleLoginError(_ message: String) {
#if os(Android)
        print("FAIL", Self.self, "Login error: \(message)")
#else
        print("FAIL", #line, Self.self, #function, "Login error: \(message)")
#endif
        errorMessage = message
        isAuthenticated = false
        isAuthenticating = false
        user = nil
    }
    
    func handleLoginError(with error: Error) {
        handleLoginError(error.localizedDescription)
    }
    
#if !os(Android)
    // Adapted from Firebase documentation
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func startSignInWithApple() -> String {
        isAuthenticating = true
        errorMessage = ""
        
        // Generate a new nonce for this sign-in attempt
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
#endif
    
    func updateUserInFirestore(uid: String, displayName: String?, email: String?) {
        // Skip if no data to update
        guard displayName != nil || email != nil else { return }
        
        // Base fields for updates (same for new or existing users)
        var userData: [String: Any] = [
            "lastSignInTime": FieldValue.serverTimestamp()
        ]
        
        // Only add fields that are not nil
        if let displayName {
            userData["displayName"] = displayName
        }
        
        if let email {
            userData["email"] = email
        }
        
        // For new users, these additional fields might be needed
        // We don't know if this is a new user, so we'll include them
        // The merge option will only add them if the document doesn't exist
        userData["creationTime"] = FieldValue.serverTimestamp()
        userData["signupTimestamp"] = FieldValue.serverTimestamp()
        userData["providerId"] = "firebase"
        userData["isAnonymous"] = false
        userData["emailVerified"] = true // Assume Apple emails are verified
        
        // Update or create Firestore document
        // Using setData with merge:true works cross-platform and handles both create/update
        Task {
            do {
                let db = Firestore.firestore()
                try await db.collection("users").document(uid).setData(userData, merge: true)
            } catch {
                print("FAIL", Self.self, "Error updating user data: \(error.localizedDescription)")
            }
        }
    }
}
