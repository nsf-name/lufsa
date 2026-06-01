// Lufsa.swift
import SwiftUI

@main
struct LufsaApp: App {
    @State var manager = WindowManager.shared
    @Environment(\.openWindow) var openWindow

    var body: some Scene {
        WindowGroup("Image", for: UUID.self) { $id in
            if let id {
                ImageStickyView(documentId: id)
            }
        }
        .defaultSize(width: 300, height: 300)
        .windowLevel(.floating)
        .windowBackgroundDragBehavior(.enabled)
        .commandsRemoved() // kind of a hack
        .commands {
            // TODO: should use CommandGroup to override stock groups,
            // rather than using .commandsRemoved() to purge stock ones.
            CommandMenu("Images") {
                Button("Open Image...", systemImage: "photo") {
                    manager.openImage(using: openWindow)
                }.keyboardShortcut(KeyboardShortcut("o"))
            }
            CommandMenu("Windows") {
                Group {
                    Toggle("Floating", isOn: Binding(
                        get: { manager.focusedDocument?.properties.isFloating ?? false },
                        set: { manager.setFloating($0) }
                    ))
                    Toggle("Half Opacity", isOn: Binding(
                        get: { manager.focusedDocument?.properties.isHalfOpacity ?? false },
                        set: { manager.setOpacity($0) }
                    ))
                    Toggle("Borders", isOn: Binding(
                        get: { manager.focusedDocument?.properties.isBorderless ?? false },
                        set: { manager.setBorders($0) }
                    ))
                }
                Button("Debug") {
                    print("DEBUG: focused document is now \(WindowManager.shared.focusedDocument?.url.lastPathComponent ?? "nil")")
                }
            }
        }
    }
}
