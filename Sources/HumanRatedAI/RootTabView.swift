import SwiftUI

public struct RootTabView: View {
    @AppStorage("tab") var tab = Tab.ai
    @State var appearance = ""
    
    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            Text("AI Bot List")
            .font(.largeTitle)
            .tabItem { Label("AI", systemImage: "face.smiling") }
            .tag(Tab.ai)

            Text("Create AI Bot")
            .tabItem { Label("Create", systemImage: "plus") }
            .font(.largeTitle)
            .tag(Tab.create)
            
            Text("Favorite AI Bots")
            .tabItem { Label("Favs", systemImage: "star") }
            .font(.largeTitle)
            .tag(Tab.favs)

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
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}

enum Tab : String, Hashable {
    case ai, create, favs, settings
}
