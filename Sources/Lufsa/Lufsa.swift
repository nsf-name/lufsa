// Lufsa.swift
import SwiftUI

struct ImageDocument: Identifiable, Hashable, Codable {
    let id: UUID
    let url: URL
    var properties: ImageWindowProperties
}

struct ImageWindowProperties: Hashable, Codable {
    let size: CGSize
    var isFloating: Bool
    var isHalfOpacity: Bool
    var isBorderless: Bool
}

@main
struct LufsaApp: App {
    @Environment(\.openWindow) var openWindow
    @State var documents: [UUID: ImageDocument] = [:]
    @State var showFileImporter = false

    var body: some Scene {
        Window("hidden", id: "app-root") {
            Color.clear.frame(width: 0, height: 0)
                .fileImporter(isPresented: $showFileImporter,
                               allowedContentTypes: [.image],
                               allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let file):
                        let image = NSImage(byReferencing: file.first!)
                        let doc = ImageDocument(id: UUID(),
                                                url: file.first!,
                                                properties: .init(size: image.size,
                                                                  isFloating: true,
                                                                  isHalfOpacity: false,
                                                                  isBorderless: false))
                        documents[doc.id] = doc
                        openWindow(value: doc.id)
                    case .failure(let error):
                        print(error)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .openImageCommand)) { _ in
                    showFileImporter = true
                    print("fired from notif")
                }
        }
        
        WindowGroup("Image", for: UUID.self) { $id in
            if let id, let doc = documents[id] {
                Image(nsImage: NSImage(byReferencing: doc.url))
                    .resizable()
                    .scaledToFit()
                    .overlay(DraggableEverywhere())
                    .background(WindowDelegateInjector(baseSize: doc.properties.size))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowLevel(.floating)
        .windowBackgroundDragBehavior(.enabled)
        .commandsRemoved()
        .commands {
            CommandMenu("Images") {
                Button("Open Image...") {
                    NotificationCenter.default.post(name: .openImageCommand, object: nil)
                    print("sent notif")
                }
                .keyboardShortcut("o")
            }
        }
    }
}

struct WindowDelegateInjector: NSViewRepresentable {
    let baseSize: CGSize

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.alphaValue = 0
            let delegate = AspectRatioDelegate(baseSize: baseSize)
            window.styleMask.insert(.fullSizeContentView)
            //window.titlebarAppearsTransparent = true
            //window.contentMinSize = NSSize(width: 100, height: 100)
            window.contentAspectRatio = baseSize
            // stable key pointer
            objc_setAssociatedObject(window, &Self.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
            window.delegate = delegate
            window.setContentSize(baseSize)
            window.alphaValue = 1
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
    
    private static var delegateKey: UInt8 = 0
}

class AspectRatioDelegate: NSObject, NSWindowDelegate {
    let aspectRatio: CGFloat

    init(baseSize: CGSize) {
        self.aspectRatio = baseSize.width / baseSize.height
    }

    func windowWillResize(_ sender: NSWindow, to targetSize: NSSize) -> NSSize {
        let titlebarHeight = sender.frame.height - (sender.contentView?.frame.height ?? 0)
        let contentHeight = targetSize.height - titlebarHeight
        let scale = targetSize.width / aspectRatio
        let byWidth = NSSize(width: targetSize.width, height: scale + titlebarHeight)
        let byHeight = NSSize(width: contentHeight * aspectRatio, height: targetSize.height)
        let areaW = byWidth.width * (byWidth.height - titlebarHeight)
        let areaH = byHeight.width * (byHeight.height - titlebarHeight)
        let targetArea = targetSize.width * contentHeight
        return abs(areaW - targetArea) < abs(areaH - targetArea) ? byWidth : byHeight
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


extension Notification.Name {
    static let openImageCommand = Notification.Name("openImageCommand")
}

