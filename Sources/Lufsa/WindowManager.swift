// WindowManager.swift
import SwiftUI

struct ImageDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    let width: CGFloat
    let height: CGFloat
}

struct ImageStickyView: View {
    @Environment(\.appearsActive) private var appearsActive
    
    @State var isActive = false
    var document: ImageDocument
    
    var body: some View {
        Image(nsImage: NSImage(byReferencing: document.url))
            .resizable()
            .scaledToFit()
            .aspectRatio(contentMode: .fit)
            .onChange(of: appearsActive) { pastState, newState in
                if newState == true {
                    isActive = true
                    // START DEBUG
                    print("DEBUG: Active: \(document.url.lastPathComponent)")
                    // END DEBUG
                } else if newState == false {
                    isActive = false
                    // START DEBUG
                    print("DEBUG: Inactive: \(document.url.lastPathComponent)")
                    // END DEBUG
                }
            }
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
            let width = NSImage(byReferencing: url).size.width
            let height = NSImage(byReferencing: url).size.height
            documents.append(ImageDocument(id: UUID(), url: url, width: width, height: height))
            // START DEBUG
            print("DEBUG: Windows are: \(documents). Contains: (\(documents.count))")
            // END DEBUG
            openWindow(value: ImageDocument(id: UUID(), url: url, width: width, height: height))
        }
    }
}
