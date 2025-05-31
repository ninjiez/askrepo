import SwiftUI

@main
struct AskRepoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Ensure the app window comes to front and is focused
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    
                    // Configure window appearance
                    if let window = NSApplication.shared.windows.first {
                        window.titlebarAppearsTransparent = true
                        window.isMovableByWindowBackground = true
                        window.titleVisibility = .hidden
                        
                        // Set minimum window size
                        window.minSize = NSSize(width: 900, height: 650)
                        
                        // Enable fullscreen mode
                        window.collectionBehavior = [.fullScreenPrimary]
                        
                        // Center the window on first launch
                        window.center()
                    }
                }
        }
        .commands {
            // Add View menu with fullscreen command
            CommandGroup(after: .windowSize) {
                Button("Enter Full Screen") {
                    NSApplication.shared.keyWindow?.toggleFullScreen(nil)
                }
                .keyboardShortcut("f", modifiers: [.control, .command])
            }
            
            // Remove default menu items that might interfere
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .undoRedo) { }
        }
    }
} 