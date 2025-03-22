// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import Foundation
import OSLog
import SwiftUI

let aiEnvironmentManager = EnvironmentManager.ai
let logger = Logger(subsystem: "ai.humanrated.app", category: "HumanRatedAI")

/// The Android SDK number we are running against, or `nil` if not running on Android
let androidSDK = ProcessInfo.processInfo.environment["android.os.Build.VERSION.SDK_INT"].flatMap({ Int($0) })

/// The shared top-level view for the app, loaded from the platform-specific App delegates below.
///
/// The default implementation merely loads the `RootTabView` for the app and logs a message.
public struct RootView : View {
    public init() {}
    
    public var body: some View {
        RootTabView()
            .environmentObject(aiEnvironmentManager)
            .task {
                logger.log("Welcome to Human Rated AI on \(androidSDK != nil ? "Android" : "Darwin")!")
                logger.warning("Android logs can be viewed in Studio or using adb logcat")
            }
    }
}

#if !os(Android)
public protocol HumanRatedAIApp : App {}

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

#if os(Android)
// adb logcat | grep System.out
public func debug(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    print(items, separator: separator, terminator: terminator)
}
#else
public func debug(_ items: Any...,
                  file: String = #file,
                  line: Int = #line,
                  function: String = #function,
                  separator: String = " ",
                  terminator: String = "\n") {
    let name = file.split(separator: "/").last?.split(separator: ".").first ?? ""
    print("\(name):\(line) \(function)", items, separator: separator, terminator: terminator)
}
#endif
