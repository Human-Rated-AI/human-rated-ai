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
                Picker("Appearance", selection: $appearance) {
                    Text("System").tag("")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                let lines = [appVersion, deviceModel, osVersion]
                ForEach(Array(lines.enumerated()), id: \.offset) { _, text in
                    Text(text)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private extension SettingsTabView {
    var appVersion: String {
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
    
    var deviceModel: String {
#if SKIP
        let deviceBrand = android.os.Build.MANUFACTURER
        let deviceModel = android.os.Build.MODEL
        let deviceName = android.os.Build.DEVICE
        return "\(deviceBrand) \(deviceModel) \(deviceName)"
#else
        "\(UIDevice.current.name)"
#endif
    }
    
    var osVersion: String {
#if SKIP
        "Android \(android.os.Build.VERSION.RELEASE)"
#else
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion)"
#endif
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
