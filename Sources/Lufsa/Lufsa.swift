// Lufsa.swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    // these two are to prevent deallocation by creating strong refs
    @MainActor private static var delegateKey: UInt8 = 0
    var windows: [NSWindow] = []
    
    // properties to be held in our singleton so the main window can touch them
    private var floatingItem: NSMenuItem!
    private var opacityItem: NSMenuItem!
    private var borderlessItem: NSMenuItem!
    private var pixelPerfectItem: NSMenuItem!
    
    // styleMask is grotesquely stateful so we need to save and restore them
    // upon removing and appending .titled otherwise bugs emerge.
    private var savedStyleMasks: [NSWindow: NSWindow.StyleMask] = [:]
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem(title: "App", action: nil, keyEquivalent: "")
        let appMenu = NSMenu(title: "App")
        appMenu.addItem(NSMenuItem(title: "About Lufsa", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide Lufsa", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        appMenu.addItem(NSMenuItem(title: "Quit Lufsa", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem(title: "File", action: nil, keyEquivalent: "")
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "Open", action: #selector(openFile), keyEquivalent: "o"))
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        NSApp.mainMenu = mainMenu
        
        let windowMenuItem = NSMenuItem(title: "Window", action: nil, keyEquivalent: "")
        let windowMenu = NSMenu(title: "Window")

        self.opacityItem = NSMenuItem(title: "Translucent", action: #selector(toggleOpacity), keyEquivalent: "t")
        self.floatingItem = NSMenuItem(title: "Floating", action: #selector(toggleFloating), keyEquivalent: "f")
        self.borderlessItem = NSMenuItem(title: "Borderless", action: #selector(toggleBorderless), keyEquivalent: "b")
        self.pixelPerfectItem = NSMenuItem(title: "Pixel-Perfect", action: #selector(togglePixelPerfect), keyEquivalent: "p")

        windowMenu.addItem(opacityItem)
        windowMenu.addItem(floatingItem)
        windowMenu.addItem(borderlessItem)
        windowMenu.addItem(pixelPerfectItem)
        windowMenu.delegate = self
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
    }
    
    // this handles setting the toggled state in the menu
    func menuWillOpen(_ menu: NSMenu) {
        guard let window = NSApp.keyWindow else { return }
        guard let canvas = window.contentView as? ImageCanvas else { return }
        floatingItem.state = window.level == .floating ? .on : .off
        opacityItem.state = window.alphaValue == 0.5 ? .on : .off
        pixelPerfectItem.state = canvas.interpolation == .none ? .on : .off
    }
    
    @MainActor
    @objc func toggleFloating() {
        guard let window = NSApp.keyWindow else { return }
        if window.level == .floating {
            window.level = .normal
        } else {
            window.level = .floating
        }
    }

    @MainActor
    @objc func toggleOpacity() {
        guard let window = NSApp.keyWindow else { return }
        window.alphaValue = window.alphaValue < 1.0 ? 1.0 : 0.5
    }
    
    @MainActor
    @objc func toggleBorderless() {
        guard let window = NSApp.keyWindow else { return }
        if window.styleMask.contains(.titled) {
            savedStyleMasks[window] = window.styleMask
            // technically, we could allow resizes here,
            // but they're buggy so I'm not going to allow it.
            window.styleMask = .borderless
            window.backgroundColor = .clear
            // borderless windows don't get focus by default
            window.makeKeyAndOrderFront(nil)
        } else {
            window.styleMask = savedStyleMasks[window] ?? [.titled, .closable, .resizable, .miniaturizable]
            savedStyleMasks.removeValue(forKey: window)
            window.backgroundColor = .windowBackgroundColor
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @MainActor
    @objc func togglePixelPerfect() {
        guard let canvas = NSApp.keyWindow?.contentView as? ImageCanvas else { return }
        if canvas.interpolation == .none {
            canvas.interpolation = .high
        } else {
            canvas.interpolation = .none
        }
    }
    
    @MainActor
    @objc func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = true
        // with this one change, we build on Yosemite
        if #available(macOS 11.0, *) {
            panel.allowedContentTypes = [.image]
        } else {
            panel.allowedFileTypes = ["public.image"]
        }
        panel.begin { response in
            guard response == .OK else { return }
                for url in panel.urls {
                    let image = NSImage(byReferencing: url)
                    let canvas = ImageCanvas(image: image)
                    let delegate = AspectScaleDelegate(baseSize: image.size)
                    
                    let window = LufsaWindow(
                        contentRect: NSRect(x: 0, y: 0, width: Int(image.size.width) as Int, height: Int(image.size.height)),
                        styleMask: [.titled, .closable, .resizable, .miniaturizable],
                        backing: .buffered,
                        defer: false
                    )
                    
                    // this is Dark Arts to create a strong reference.
                    // *ptr to heap of main actor, which holds it.
                    // https://nshipster.com/associated-objects/
                    objc_setAssociatedObject(window, &Self.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
                    window.delegate = delegate
                    window.title = url.lastPathComponent
                    window.contentView = canvas
                    
                    let screen = NSScreen.main!.visibleFrame
                    let width = min(image.size.width, screen.width)
                    let height = width / (image.size.width / image.size.height)
                    window.setContentSize(NSSize(width: width, height: height))
                    window.isMovableByWindowBackground = true
                    
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                    self.windows.append(window)
            }
            
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

// borderless windows mess with this, so force it to be true
final class LufsaWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class PixelImageView: NSImageView {
    // interp has to be disabled for pixel-perfection
    // this is the AppKit equivalent.
    // https://twocentstudios.com/2025/03/10/pixel-art-swift-ui/
    var interpolation: NSImageInterpolation = .high
    
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.imageInterpolation = interpolation
        super.draw(dirtyRect)
    }
}

final class ImageCanvas: NSView {
    private let imageView = PixelImageView()
    private let draggableView = DraggableView()
    var interpolation: NSImageInterpolation {
        get { imageView.interpolation }
        set { imageView.interpolation = newValue; imageView.needsDisplay = true }
    }

    init(image: NSImage) {
        super.init(frame: .zero)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        addSubview(imageView)
        addSubview(draggableView)
    }

    override func layout() {
        super.layout()
        imageView.frame = bounds
        draggableView.frame = bounds
    }

    required init?(coder: NSCoder) { fatalError("no nibs") }
}

final class AspectScaleDelegate: NSObject, NSWindowDelegate {
    private let aspectRatio: CGFloat
    
    init(baseSize: CGSize) {
        self.aspectRatio = baseSize.width / baseSize.height
    }
    
    func windowWillResize(_ sender: NSWindow, to targetSize: NSSize) -> NSSize {
        let titlebarHeight = sender.frame.height - (sender.contentView?.frame.height ?? 0)
        let contentHeight = targetSize.height - titlebarHeight
        
        let scale = targetSize.width / aspectRatio
        
        let byWidth = NSSize(width: targetSize.width, height: scale + titlebarHeight)
        let byHeight = NSSize(width: contentHeight * aspectRatio, height: targetSize.height)
        
        // we have to calculate the rectangle while titlebar into account
        let areaW = byWidth.width * (byWidth.height - titlebarHeight)
        let areaH = byHeight.width * (byHeight.height - titlebarHeight)
        
        // now this gives us a correct scaling regardless of area
        let targetArea = targetSize.width * contentHeight
        return abs(areaW - targetArea) < abs(areaH - targetArea) ? byWidth : byHeight
    }
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
