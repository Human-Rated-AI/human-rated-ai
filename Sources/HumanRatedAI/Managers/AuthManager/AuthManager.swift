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
import FirebaseAuth
import FirebaseFirestore
#endif
import SwiftUI

public class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String = ""
    @Published var user: User?
    
    /// Current nonce for Apple Sign In
    var currentNonce: String?
    var googleSignInCompletion: (() -> Void)?
    public static let shared = AuthManager()
    
    private init() {
        begin()
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
}

extension AuthManager {
    func handleLoginError(_ message: String) {
        debug("FAIL", Self.self, "Login error: \(message)")
        errorMessage = message
        isAuthenticated = false
        isAuthenticating = false
        user = nil
    }
    
    func handleLoginError(with error: Error) {
        handleLoginError(error.localizedDescription)
    }
    
    func handleSuccessfulLogin(displayName: String?, email: String?, uid: String) {
        errorMessage = ""
        isAuthenticated = true
        isAuthenticating = false
        user = User(displayName: displayName, email: email, uid: uid)
        // Update Firestore document
        updateUserInFirestore(uid: uid, displayName: displayName, email: email)
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
    
    func startAuthenticating() {
        isAuthenticating = true
        errorMessage = ""
    }
}

private extension AuthManager {
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
                try await db.users.document(uid).setData(userData, merge: true)
            } catch {
                debug("FAIL", Self.self, "Error updating user data: \(error.localizedDescription)")
            }
        }
    }
}
