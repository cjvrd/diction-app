import SwiftUI

@main
struct diction_macos_appApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "mic.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
