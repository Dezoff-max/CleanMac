import AppKit
import SwiftUI

enum MainWindowController {
    static let identifier = NSUserInterfaceItemIdentifier("CleanMacMainWindow")

    @MainActor
    static func configure(_ window: NSWindow) {
        window.identifier = identifier
        window.tabbingMode = .disallowed
    }

    @MainActor
    static func show(openWindow: OpenWindowAction) {
        if let existingWindow = NSApp.windows.first(where: { $0.identifier == identifier }) {
            existingWindow.deminiaturize(nil)
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                onResolve(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                onResolve(window)
            }
        }
    }
}
