// WindowManager.swift
import SwiftUI

// SwiftUI gives us no way to fetch a NSWindow,
// so we need to use this in order to get one.
struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?
    var document: ImageDocument?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            guard let image = document?.properties else { return }
            self.window = window

            // snap to ratio immediately, use correct aspect
            if image.isBorderless {
                window.aspectRatio = image.aspectRatio
            } else {
                window.aspectRatio = NSSize(width: image.aspectRatio.width,
                                            height: image.aspectRatio.height + window.titlebarHeight)
            }
            let aspect = image.aspectRatio.width / image.aspectRatio.height
            let w = window.frame.width
            let h = w / aspect + window.titlebarHeight
            window.setFrame(CGRect(origin: window.frame.origin, size: NSSize(width: w, height: h)), display: true)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// it's cleaner to write this as an extension
extension NSWindow {
    var titlebarHeight: CGFloat {
        frame.height - contentRect(forFrameRect: frame).height
    }
}

// wrapper NSView that makes any location on the window draggable.
struct DraggableEverywhere: NSViewRepresentable {
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
        // we use NSPoint so it works at any DPI (Retina displays)
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
            let size = NSImage(byReferencing: url).size
            let properties = ImageWindowProperties(size: size, aspectRatio: NSSize(width: size.width, height: size.height), isFloating: true, isHalfOpacity: false, isBorderless: false)
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
