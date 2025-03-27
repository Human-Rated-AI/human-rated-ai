// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import FirebaseCore
import GoogleSignIn
import HumanRatedAI
import SwiftUI

/// The entry point to the app simply loads the App implementation from SPM module.
@main struct AppMain: App, HumanRatedAIApp {
    @UIApplicationDelegateAdaptor(FireSideAppDelegate.self) var appDelegate
}

class FireSideAppDelegate : NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        debug("INFO", Self.self, "FirebaseApp configured")
        return true
    }
    
    // Handle URL scheme callback for Google Sign In
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign In callback
        if GIDSignIn.sharedInstance.handle(url) {
            debug("INFO", Self.self, "Google Sign In URL handled")
            return true
        }
        
        debug("WARN", Self.self, "URL not handled: \(url)")
        return false
    }
}
