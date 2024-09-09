//
//  SettingsTabView.swift
//  Human Rated AI
//
//  Created by Denis Bystruev on 9/8/24.
//

import SwiftUI

struct SettingsTabView: View {
    @Binding var appearance: String
    
    var body: some View {
        NavigationStack {
            Form {
                Text(version)
                    .foregroundStyle(.gray)
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag("")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private extension SettingsTabView {
    var version: String {
#if SKIP
        // Asked for help https://github.com/orgs/skiptools/discussions/223
        let context = ProcessInfo.processInfo.androidContext
        let displayName = "Hurated AI"
        let metaData = android.content.pm.PackageManager.GET_META_DATA
        let packageManager = context.getPackageManager()
        let packageName = context.getPackageName()
        let packageInfo = packageManager.getPackageInfo(packageName, metaData)
        let appVersionLong = packageInfo.versionName
        let appBuild = "\(packageInfo.versionCode)"
#else
        let displayName = Bundle.main.displayName
        let appVersionLong = Bundle.main.appVersionLong
        let appBuild = Bundle.main.appBuild
#endif
        return "\(displayName) v\(appVersionLong) build \(appBuild.inserting(".", at: [4, 6]))"
    }
}

#if !SKIP
// https://stackoverflow.com/a/68912269/7851379
private extension Bundle {
    var appBuild: String { getInfo("CFBundleVersion") }
    var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    var displayName: String { getInfo("CFBundleDisplayName") }
    func getInfo(_ string: String) -> String { infoDictionary?[string] as? String ?? "⚠️" }
}
#endif
