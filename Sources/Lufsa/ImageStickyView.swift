// ImageStickyView.swift
import SwiftUI

struct ImageDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    var properties: ImageWindowProperties
}

// TODO: we should make this an enum so that our WindowManager
// setters are generic over any property since they're pretty similar
struct ImageWindowProperties: Hashable, Codable {
    // size can be changed, but aspectRatio is fixed at creation-time
    var size: CGSize
    let aspectRatio: NSSize
    var isFloating: Bool
    var isHalfOpacity: Bool
    var isBorderless: Bool
}

struct ImageStickyView: View {
    @Environment(\.appearsActive) private var appearsActive
    @State private var window: NSWindow?
    
    @State var isActive = false
    let documentId: UUID
    var document: ImageDocument? {
        WindowManager.shared.documents.first { $0.id == documentId }
    }
    
    var body: some View {
        if let document {
            Image(nsImage: NSImage(byReferencing: document.url))
                // remove image distortion so images are pixel-perfect
                // https://twocentstudios.com/2025/03/10/pixel-art-swift-ui/
                .antialiased(false)
                .interpolation(.none)
                .resizable()
                .scaledToFill()
                // TODO: this should be set up better
                .frame(minWidth: document.properties.size.width * 0.5, maxWidth: .infinity, minHeight: document.properties.size.height * 0.5, maxHeight: .infinity)
                .background(.clear)
                .aspectRatio(contentMode: .fit)
                .navigationTitle(document.url.lastPathComponent)
                .overlay(WindowAccessor(window: $window, document: document))
                .overlay(DraggableEverywhere())
                .onChange(of: appearsActive) { _, isActive in
                    if isActive {
                        WindowManager.shared.focusedDocument = document
                        print("DEBUG: focused document is now \(WindowManager.shared.focusedDocument?.url.lastPathComponent ?? "nil")")
                    }
                }
                .onChange(of: document.properties.isHalfOpacity) { _, val in
                    window?.alphaValue = val ? 0.5 : 1.0
                }
                .onChange(of: document.properties.isFloating) { _, val in
                    window?.level = val ? .popUpMenu : .normal
                }
                .onChange(of: document.properties.isBorderless) { _, isBorderless in
                    if isBorderless {
                        window?.styleMask = [.borderless, .fullSizeContentView, .resizable]
                        window?.titlebarAppearsTransparent = true
                        window?.titleVisibility = .hidden
                        window?.backgroundColor = .clear
                        window?.isOpaque = false
                        window?.aspectRatio = document.properties.aspectRatio
                    } else {
                        window?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                        window?.titlebarAppearsTransparent = false
                        window?.titleVisibility = .visible
                        window?.backgroundColor = .windowBackgroundColor
                        window?.isOpaque = true
                        window?.aspectRatio = NSSize(width: document.properties.aspectRatio.width,
                                                     height: document.properties.aspectRatio.height + window!.titlebarHeight)
                    }
                }
        }
    }
}

