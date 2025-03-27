// This is free software: you can redistribute and/or modify it
// under the terms of the GNU General Public License 3.0
// as published by the Free Software Foundation https://fsf.org

import SwiftUI

public struct RootTabView: View {
    @AppStorage("appearance") private var appearance = ""
    @AppStorage("tab") private var tab = Tab.ai
    @StateObject private var authManager = AuthManager.shared
    @State private var showAuthSheet = false
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $tab) {
            // AI Tab - accessible to all users
            AITabView()
                .tabItem { Label("AI", systemImage: "face.smiling") }
                .tag(Tab.ai)
            
            // Create Tab - requires authentication
            Group {
                if authManager.isAuthenticated {
                    CreateTabView()
                } else {
                    NeedToAuthorize(showAuthSheet: $showAuthSheet, reason: "to create AI bots")
                }
            }
            .tabItem { Label("Create", systemImage: "plus") }
            .tag(Tab.create)
            
            // Favorites Tab - requires authentication
            Group {
                if authManager.isAuthenticated {
                    FavsTabView()
                } else {
                    NeedToAuthorize(showAuthSheet: $showAuthSheet, reason: "to view your favorites")
                }
            }
            .tabItem { Label("Favs", systemImage: "star") }
            .tag(Tab.favs)
            
            // Settings Tab - requires authentication
            Group {
                if authManager.isAuthenticated {
                    SettingsTabView(appearance: $appearance)
                } else {
                    NeedToAuthorize(showAuthSheet: $showAuthSheet, reason: "to manage the settings")
                }
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthView(showAuthSheet: $showAuthSheet)
        }
        .environmentObject(authManager)
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
#if !os(Android)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            // This ensures the tab bar has proper contrast in any mode
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
#endif
    }
}

private enum Tab: String, Hashable {
    case ai, create, favs, settings
}
