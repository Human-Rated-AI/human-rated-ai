package human.rated.ai

import android.content.Intent
import android.util.Log

// Extension methods for MainActivity to handle authentication
class MainActivityAuthHandler {
    companion object {
        // Method to handle authentication results in the MainActivity
        @JvmStatic
        fun handleActivityResult(activity: android.app.Activity, requestCode: Int, resultCode: Int, data: Intent?) {
            // Add more logging here
            android.util.Log.d("MainActivityAuthHandler", "handleActivityResult called with requestCode: $requestCode")

            if (requestCode == 9001) { // Google Sign-In request code
                android.util.Log.d("MainActivityAuthHandler", "Google Sign-In result received")
                try {
                    // Get the AuthManager singleton directly instead of using reflection
                    human.rated.ai.AuthManager.shared.handleGoogleSignInResult(data)
                    android.util.Log.d("MainActivityAuthHandler", "Successfully passed result to AuthManager")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivityAuthHandler", "Error handling Google Sign-In result", e)
                }
            }
        }
    }
}
