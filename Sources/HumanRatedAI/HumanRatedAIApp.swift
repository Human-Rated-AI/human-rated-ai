import Foundation
import OSLog
import SwiftUI

let logger: Logger = Logger(subsystem: "ai.humanrated.app", category: "HumanRatedAI")

/// The Android SDK number we are running against, or `nil` if not running on Android
let androidSDK = ProcessInfo.processInfo.environment["android.os.Build.VERSION.SDK_INT"].flatMap({ Int($0) })

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
///
/// The default implementation merely loads the `RootTabView` for the app and logs a message.
public struct RootView : View {
    public init() {
    }

    public var body: some View {
        RootTabView()
            .task {
                logger.log("Welcome to Human Rated AI on \(androidSDK != nil ? "Android" : "Darwin")!")
                logger.warning("Android logs can be viewed in Studio or using adb logcat")
            }
    }
}

#if !SKIP
public protocol HumanRatedAIApp : App {
}

/// The entry point to the HumanRatedAI app.
/// The concrete implementation is in the HumanRatedAIApp module.
public extension HumanRatedAIApp {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
#endif
