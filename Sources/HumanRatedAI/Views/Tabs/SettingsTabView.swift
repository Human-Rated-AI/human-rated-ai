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
                .foregroundStyle(.gray)
            }
            .navigationTitle("Settings")
        }
    }
}
