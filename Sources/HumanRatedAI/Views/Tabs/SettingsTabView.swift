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
                Text("\(Bundle.main.displayName) v\(Bundle.main.appVersionLong) build \(Bundle.main.appBuild)")
                    .foregroundStyle(.gray)
            }
            .navigationTitle("Settings")
        }
    }
}

// https://stackoverflow.com/a/68912269/7851379
private extension Bundle {
    var appBuild: String { getInfo("CFBundleVersion") }
    var appVersionLong: String { getInfo("CFBundleShortVersionString") }
    var displayName: String { getInfo("CFBundleDisplayName") }
    
    func getInfo(_ string: String) -> String {
#if SKIP
        "⚠️"
#else
        infoDictionary?[string] as? String ?? "⚠️"
#endif
    }
}
