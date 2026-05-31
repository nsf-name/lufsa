// WindowManager.swift
import SwiftUI

struct ImageDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    var properties: ImageWindowProperties
}

struct ImageWindowProperties: Hashable, Codable {
    let width: CGFloat
    let height: CGFloat
    
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
                .resizable()
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .navigationTitle(document.url.lastPathComponent)
                .overlay(WindowAccessor(window: $window))
                .overlay(DraggableBackground())
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
                        window?.styleMask = [.borderless, .fullSizeContentView]
                        window?.titlebarAppearsTransparent = true
                        window?.titleVisibility = .hidden
                        window?.backgroundColor = .clear
                        window?.isOpaque = false
                    } else {
                        window?.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                        window?.titlebarAppearsTransparent = false
                        window?.titleVisibility = .visible
                        window?.backgroundColor = .windowBackgroundColor
                        window?.isOpaque = true
                    }
                }
        }
    }
}

// SwiftUI gives us no way to fetch a NSWindow,
// so we need to use this in order to get one.
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct DraggableBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> DraggableView { DraggableView() }
    func updateNSView(_ nsView: DraggableView, context: Context) {}
}

class DraggableView: NSView {
    private var initialLocation: NSPoint?

    override func mouseDown(with event: NSEvent) {
        initialLocation = NSEvent.mouseLocation
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = window else { return }
        window.setFrameOrigin(NSPoint(
            x: window.frame.origin.x + event.deltaX,
            y: window.frame.origin.y - event.deltaY  // y is flipped
        ))
    }

    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

@MainActor
@Observable
class WindowManager {
    // this is a singleton
    static let shared = WindowManager()
    // TODO: make this persist with UserDefaults
    var documents: [ImageDocument] = []
    var focusedDocument: ImageDocument?
    
    func openImage(using openWindow: OpenWindowAction) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        panel.urls.forEach { url in
            let width = NSImage(byReferencing: url).size.width
            let height = NSImage(byReferencing: url).size.height
            let properties = ImageWindowProperties(width: width, height: height, isFloating: true, isHalfOpacity: false, isBorderless: false)
            let document = ImageDocument(id: UUID(), url: url, properties: properties)
            documents.append(document)
            focusedDocument = document
            // START DEBUG
            print("DEBUG: Windows are: \(documents). Contains: (\(documents.count))")
            // END DEBUG
            openWindow(value: document.id)
        }
    }
    
    func setOpacity(_ isHalfOpacity: Bool) {
        guard let i = documents.firstIndex(where: { $0.id == focusedDocument?.id }) else { return }
        documents[i].properties.isHalfOpacity = isHalfOpacity
        print("opacity set to: \(isHalfOpacity ? 0.5 : 1.0)")
        focusedDocument = documents[i]  // keep focused in sync
    }
    
    func setFloating(_ isFloating: Bool) {
        guard let i = documents.firstIndex(where: { $0.id == focusedDocument?.id }) else { return }
        documents[i].properties.isFloating = isFloating
        print("floating set to: \(isFloating ? "true" : "false")")
        focusedDocument = documents[i]
    }
    
    func setBorders(_ isBorderless: Bool) {
        guard let i = documents.firstIndex(where: { $0.id == focusedDocument?.id }) else { return }
        documents[i].properties.isBorderless = isBorderless
        print("borders set to: \(isBorderless ? "true" : "false")")
        focusedDocument = documents[i] 
    }
}
