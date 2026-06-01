// main.swift
import AppKit

// why not @main? because I need tighter control over the delegate.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
