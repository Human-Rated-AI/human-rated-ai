// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

//
//  SettingsTabView.swift
//  Human Rated AI
//
//  Created by Denis Bystruev on 9/8/24.
//

import SwiftUI

struct SettingsTabView: View {
    @Binding var appearance: String
    @EnvironmentObject var aiEnvironmentManager: EnvironmentManager
    @EnvironmentObject var authManager: AuthManager
    @State var errorMessage = ""
    @State var models = [String]()
    
    var body: some View {
        NavigationStack {
            List {
                Section("App") {
                    ListSettingsView(list: [appVersion, deviceModel, osVersion])
                }
                if let user = authManager.user {
                    Section("User") {
                        ListSettingsView(list: [user.displayName?.nonEmptyTrimmed ?? "Name not shared",
                                                user.email?.nonEmptyTrimmed ?? "E-mail not shared"])
                    }
                }
                Section("Deployment") {
                    ListSettingsView(list: aiInfo)
                }
                if errorMessage.notEmpty {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                    
                }
                if models.isNotEmpty {
                    Section("Models") {
                        ListSettingsView(list: models)
                    }
                }
                Section("Settings") {
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section {
                    if authManager.user != nil {
                        Button("Log Out") {
                            authManager.signOut()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            Task {
                do {
                    let deployments = try await NetworkManager.ai?.getDeployments()
                    if let deployments {
                        let modelNames = deployments.map { "\($0.properties.model.name)" }
                        models = Set(modelNames).sorted()
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

private extension SettingsTabView {
    var aiInfo: [String] {
        [aiEnvironmentManager.aiModel ?? "unknown"]
    }
    
    var appVersion: String {
#if os(Android)
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
#if os(Android)
        let deviceBrand = android.os.Build.MANUFACTURER
        let deviceModel = android.os.Build.MODEL
        let deviceName = android.os.Build.DEVICE
        return "\(deviceBrand) \(deviceModel) \(deviceName)"
#else
        let model = UIDevice.current.localizedModel
        let name = UIDevice.current.name
        if model.contains(name) { return model }
        if name.contains(model) { return name }
        return "\(model) \(name)"
#endif
    }
    
    var osVersion: String {
#if os(Android)
        "Android \(android.os.Build.VERSION.RELEASE)"
#else
        let device = UIDevice.current
        return "\(device.systemName) \(device.systemVersion)"
#endif
    }
}

#if !os(Android)
// https://stackoverflow.com/a/68912269/7851379
private extension Bundle {
    var appBuild: String { getInfo("CFBundleVersion") }
    var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    var displayName: String { getInfo("CFBundleDisplayName") }
    func getInfo(_ string: String) -> String { infoDictionary?[string] as? String ?? "⚠️" }
}
#endif

private struct ListSettingsView: View {
    let list: [String]
    var body: some View {
        ForEach(Array(list.enumerated()), id: \.offset) { _, text in
            Text(text)
                .foregroundStyle(.gray)
        }
    }
}
