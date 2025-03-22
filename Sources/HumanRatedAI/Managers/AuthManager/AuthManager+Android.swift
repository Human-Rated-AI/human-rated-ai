// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  AuthManager+Android.swift
//  human-rated-ai
//
//  Created by Denis Bystruev on 3/22/25.
//

#if os(Android)
extension AuthManager {
    func begin() {
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
    }
    
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
    
    func signInWithApple(completion: (() -> Void)? = nil) {
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
    }
    
    func signInWithGoogle(completion: (() -> Void)? = nil) {
        startAuthenticating()
        // Store the completion handler
        googleSignInCompletion = completion
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
    }
    
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
}
#endif
