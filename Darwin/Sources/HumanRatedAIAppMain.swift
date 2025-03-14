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
        print("INFO", #line, Self.self, #function, "FirebaseApp configured")
        return true
    }
    
    // Handle URL scheme callback for Google Sign In
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign In callback
        if GIDSignIn.sharedInstance.handle(url) {
            print("INFO", #line, Self.self, #function, "Google Sign In URL handled")
            return true
        }
        
        print("WARNING", #line, Self.self, #function, "URL not handled: \(url)")
        return false
    }
}
