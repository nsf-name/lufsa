// Lufsa.swift
import SwiftUI

@main
struct LufsaApp: App {
    @State private var manager = WindowManager()
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        WindowGroup(for: ImageDocument.self) { $doc in
            if let doc {
                ImageStickyView(document: doc)
            }
        }
        .windowLevel(.floating)
        .windowBackgroundDragBehavior(.enabled)
        .commandsRemoved()
        .commands {
            // TODO: should use CommandGroup to override stock groups,
            // rather than using .commandsRemoved() to purge stock ones.
            CommandMenu("Images") {
                Button("Open Image...", systemImage: "photo") {
                    manager.openImage(using: openWindow)
                }.keyboardShortcut(KeyboardShortcut("o"))
            }
        }
    }
}
