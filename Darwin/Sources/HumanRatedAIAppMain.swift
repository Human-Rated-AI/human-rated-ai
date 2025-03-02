// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import FirebaseCore
import SwiftUI
import HumanRatedAI

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
}
