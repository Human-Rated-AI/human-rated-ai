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

public class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String = ""
    @Published var user: User?
    
    /// Current nonce for Apple Sign In
    private var currentNonce: String?
    private var googleSignInCompletion: (() -> Void)?
    public static let shared = AuthManager()
    
    private init() {
#if os(Android)
        // SKIP INSERT:
        // // Add Firebase auth state listener for Android
        // com.google.firebase.auth.FirebaseAuth.getInstance().addAuthStateListener { auth ->
        //     val currentUser = auth.currentUser
        //     android.os.Handler(android.os.Looper.getMainLooper()).post {
        //         isAuthenticated = currentUser != null
        //         user = currentUser?.let {
        //             User(
        //                 displayName = it.displayName,
        //                 email = it.email,
        //                 uid = it.uid
        //             )
        //         }
        //         android.util.Log.d("AuthManager", "Auth state changed: authenticated=${isAuthenticated}, user=${user?.email}")
        //     }
        // }
#else
        // Listen for authentication state changes in iOS
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
}

extension AuthManager {
#if os(Android)
    public func handleGoogleSignInResult(data: Any?) {
        // SKIP INSERT:
        // android.util.Log.d("AuthManager", "Handling Google Sign-In result")
        // try {
        //     if (data == null) {
        //         android.util.Log.e("AuthManager", "Sign-in result data is null")
        //         android.os.Handler(android.os.Looper.getMainLooper()).post {
        //             handleLoginError("Google Sign-In failed: No result data")
        //             isAuthenticating = false
        //         }
        //         return
        //     }
        //     val intent = data as? android.content.Intent
        //     if (intent == null) {
        //         android.util.Log.e("AuthManager", "Sign-in result is not an Intent")
        //         android.os.Handler(android.os.Looper.getMainLooper()).post {
        //             handleLoginError("Google Sign-In failed: Invalid result format")
        //             isAuthenticating = false
        //         }
        //         return
        //     }
        //     android.util.Log.d("AuthManager", "Getting account from intent")
        //     val task = com.google.android.gms.auth.api.signin.GoogleSignIn.getSignedInAccountFromIntent(intent)
        //     task.addOnSuccessListener { account ->
        //         android.util.Log.d("AuthManager", "Google account retrieved: ${account.email}")
        //         val idToken = account.idToken
        //         if (idToken == null) {
        //             android.util.Log.e("AuthManager", "Google Sign-In ID token is null")
        //             android.os.Handler(android.os.Looper.getMainLooper()).post {
        //                 handleLoginError("Failed to get ID token from Google")
        //                 isAuthenticating = false
        //             }
        //             return@addOnSuccessListener
        //         }
        //         android.util.Log.d("AuthManager", "Creating Firebase credential with ID token")
        //         val credential = com.google.firebase.auth.GoogleAuthProvider.getCredential(idToken, null)
        //         android.util.Log.d("AuthManager", "Signing in with Firebase")
        //         com.google.firebase.auth.FirebaseAuth.getInstance().signInWithCredential(credential)
        //             .addOnCompleteListener { authTask ->
        //                 if (authTask.isSuccessful) {
        //                     android.util.Log.d("AuthManager", "Firebase auth successful")
        //                     val user = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser
        //                     if (user != null) {
        //                         android.util.Log.d("AuthManager", "User signed in: ${user.email}")
        //                         android.os.Handler(android.os.Looper.getMainLooper()).post {
        //                             handleSuccessfulLogin(
        //                                 displayName = user.displayName,
        //                                 email = user.email,
        //                                 uid = user.uid
        //                             )
        //                             // Call the stored completion handler if it exists
        //                             googleSignInCompletion?.invoke()
        //                             // Clear the stored completion handler
        //                             googleSignInCompletion = null
        //                         }
        //                     } else {
        //                         android.util.Log.e("AuthManager", "Firebase user is null after successful auth")
        //                         android.os.Handler(android.os.Looper.getMainLooper()).post {
        //                             handleLoginError("Failed to get user information from Firebase")
        //                             isAuthenticating = false
        //                         }
        //                     }
        //                 } else {
        //                     android.util.Log.e("AuthManager", "Firebase auth failed: ${authTask.exception?.message}")
        //                     android.os.Handler(android.os.Looper.getMainLooper()).post {
        //                         handleLoginError(authTask.exception?.message ?: "Firebase authentication failed")
        //                         isAuthenticating = false
        //                     }
        //                 }
        //             }
        //     }.addOnFailureListener { e ->
        //         val statusCode = if (e is com.google.android.gms.common.api.ApiException) e.statusCode else -1
        //         val statusMessage = e.message ?: "Unknown error"
        //         android.util.Log.e("AuthManager", "Google Sign-In API exception: $statusCode - $statusMessage")
        //         android.os.Handler(android.os.Looper.getMainLooper()).post {
        //             handleLoginError("Google Sign-In failed with error code: $statusCode")
        //             isAuthenticating = false
        //         }
        //     }
        // } catch (e: Exception) {
        //     android.util.Log.e("AuthManager", "Error during Google Sign-In: ${e.message}", e)
        //     android.os.Handler(android.os.Looper.getMainLooper()).post {
        //         handleLoginError("Error during Google Sign-In: ${e.message}")
        //         isAuthenticating = false
        //     }
        // }
    }
#endif
    
    func handleLoginError(with error: Error) {
        handleLoginError(error.localizedDescription)
    }
    
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
    
    func signInWithApple(completion: (() -> Void)? = nil) {
        isAuthenticating = true
        errorMessage = ""
        
#if os(Android)
        // SKIP INSERT:
        // try {
        //     // Get the current activity using our helper method
        //     val activity = getCurrentActivity() as? android.app.Activity
        //     if (activity != null) {
        //         // Show the dialog using the activity context
        //         val builder = android.app.AlertDialog.Builder(activity)
        //         builder.setTitle("Apple Sign In Not Available")
        //         builder.setMessage("Apple Sign In is not available on Android devices. Would you like to sign in with Google instead?")
        //         builder.setPositiveButton("Sign in with Google") { _, _ ->
        //             signInWithGoogle(completion)
        //         }
        //         builder.setNegativeButton("Cancel") { _, _ ->
        //             handleLoginError("Authentication cancelled")
        //         }
        //         builder.show()
        //     } else {
        //         // Try using the application context as a fallback
        //         android.util.Log.e("AuthManager", "Could not get a valid Activity for Apple dialog")
        //         handleLoginError("Cannot display dialog: no active Activity found")
        //     }
        // } catch (e: Exception) {
        //     android.util.Log.e("AuthManager", "Failed to show Apple Sign-In dialog: ${e.message}")
        //     handleLoginError("Failed to show authentication dialog: ${e.message}")
        // }
#else
        // iOS implementation should use SignInWithAppleButton
        handleLoginError("Should be implemented on iOS using SignInWithAppleButton")
#endif
    }
    
    func signInWithGoogle(completion: (() -> Void)? = nil) {
        isAuthenticating = true
        errorMessage = ""
        
        // Store the completion handler
        googleSignInCompletion = completion
#if os(Android)
        // SKIP INSERT:
        // try {
        //     // Log the start of Google Sign-In
        //     android.util.Log.d("AuthManager", "Starting Google Sign-In flow")
        //     // Get the current activity using our helper method
        //     val activity = getCurrentActivity() as? android.app.Activity
        //     if (activity != null) {
        //         // Get the web client ID from environment
        //         val oauthClientID = EnvironmentManager.ai.oauthClientID ?: "OAUTH_CLIENT_ID"
        //         android.util.Log.d("AuthManager", "Using OAuth client ID: $oauthClientID")
        //         // Build Google Sign-In options
        //         val gso = com.google.android.gms.auth.api.signin.GoogleSignInOptions.Builder(
        //             com.google.android.gms.auth.api.signin.GoogleSignInOptions.DEFAULT_SIGN_IN
        //         )
        //         .requestIdToken(oauthClientID)
        //         .requestEmail()
        //         .build()
        //         // Create the client
        //         val googleSignInClient = com.google.android.gms.auth.api.signin.GoogleSignIn.getClient(activity, gso)
        //         // Sign out first to ensure we get the account picker
        //         googleSignInClient.signOut().addOnCompleteListener {
        //             android.util.Log.d("AuthManager", "Previous sign-in state cleared")
        //             // Create sign-in intent
        //             val signInIntent = googleSignInClient.signInIntent
        //             // Start the activity
        //             activity.startActivityForResult(signInIntent, 9001)
        //             android.util.Log.d("AuthManager", "Google Sign-In activity started with request code 9001")
        //         }
        //     } else {
        //         // Handle the case where we can't get an activity
        //         android.util.Log.e("AuthManager", "Could not get a valid Activity")
        //         handleLoginError("Cannot initiate Google Sign-In: No active Activity found")
        //         isAuthenticating = false
        //     }
        // } catch (e: Exception) {
        //     // Log and handle any exceptions
        //     android.util.Log.e("AuthManager", "Error starting Google Sign-In: ${e.message}", e)
        //     handleLoginError("Failed to start Google Sign-In: ${e.message}")
        //     isAuthenticating = false
        // }
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
    
#if !os(Android)
    func startSignInWithApple() -> String {
        isAuthenticating = true
        errorMessage = ""
        
        // Generate a new nonce for this sign-in attempt
        let nonce = randomNonceString()
        currentNonce = nonce
        return nonce
    }
#endif
}

private extension AuthManager {
#if os(Android)
    func getCurrentActivity() -> Any? {
        // SKIP INSERT:
        // try {
        //     // Get the current Activity Thread class
        //     val activityThreadClass = Class.forName("android.app.ActivityThread")
        //     val currentActivityThreadMethod = activityThreadClass.getDeclaredMethod("currentActivityThread")
        //     currentActivityThreadMethod.isAccessible = true
        //     val currentActivityThread = currentActivityThreadMethod.invoke(null)
        //     // Get the Activity from the ActivityThread
        //     val activitiesField = activityThreadClass.getDeclaredField("mActivities")
        //     activitiesField.isAccessible = true
        //     val activities = activitiesField.get(currentActivityThread) as android.util.ArrayMap<*, *>
        //     // Find the current activity
        //     for (activityRecord in activities.values) {
        //         val activityRecordClass = activityRecord.javaClass
        //         val activityField = activityRecordClass.getDeclaredField("activity")
        //         activityField.isAccessible = true
        //         val activity = activityField.get(activityRecord) as? android.app.Activity
        //         if (activity != null) {
        //             return activity
        //         }
        //     }
        //     return null
        // } catch (e: Exception) {
        //     android.util.Log.e("AuthManager", "Failed to get current activity: ${e.message}")
        //     return null
        // }
        return nil
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
#endif
    
#if os(Android)
    static func startGoogleSignIn(from activity: Any) {
        // SKIP INSERT:
        // android.util.Log.d("AuthManager", "startGoogleSignIn method called (deprecated)")
        // // This method is deprecated but kept for compatibility
        // // Call signInWithGoogle() instead
        // if (activity !is android.app.Activity) {
        //     android.util.Log.e("AuthManager", "Not an activity")
        //     return
        // }
        // try {
        //     shared.signInWithGoogle()
        // } catch (e: Exception) {
        //     android.util.Log.e("AuthManager", "Error in startGoogleSignIn: ${e.message}")
        //     shared.handleLoginError("Failed to start Google Sign-In: ${e.message}")
        // }
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
