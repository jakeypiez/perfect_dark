import SwiftUI

@main
struct PerfectDarkLauncherApp: App {
    @StateObject private var gameSettings = GameSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameSettings)
        }
        .windowStyle(.hiddenTitleBar)
        
        Settings {
            SettingsView()
                .environmentObject(gameSettings)
        }
    }
}
