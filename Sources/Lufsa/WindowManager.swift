// WindowManager.swift
import SwiftUI

struct ImageDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
}

struct ImageStickyView: View {
    var document: ImageDocument
    
    var body: some View {
        Image(nsImage: NSImage(byReferencing: document.url))
    }
}

@MainActor
class WindowManager: Observable {
    var documents: [ImageDocument] = []
    
    func openImage(using openWindow: OpenWindowAction) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        panel.urls.forEach { url in
            documents.append(ImageDocument(id: UUID(), url: url))
            // START DEBUG
            print("DEBUG: Windows are: \(documents). Contains: (\(documents.count))")
            // END DEBUG
            openWindow(value: ImageDocument(id: UUID(), url: url))
        }
    }
}
