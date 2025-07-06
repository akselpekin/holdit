import SwiftUI

@main
struct HoldItApp: App {
    init() {
        // Ensure a regular Dock icon & menu bar appear
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup("holdit") {
            // A green full-window view; define ContentView elsewhere
            Tray()
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}
