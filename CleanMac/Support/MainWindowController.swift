import AppKit
import ObjectiveC
import SwiftUI

enum MainWindowController {
    static let identifier = NSUserInterfaceItemIdentifier("CleanMacMainWindow")
    private static let preferredInitialSize = NSSize(width: 980, height: 720)
    private static let minimumSize = NSSize(width: 900, height: 680)
    private static var fittedWindowIDs = Set<ObjectIdentifier>()
    private static var suppressInitialPresentation = false
    @MainActor private static var closeDelegateAssociation: UInt8 = 0

    @MainActor
    static func prepareForInitialPresentation(isBackgroundLaunch: Bool) {
        suppressInitialPresentation = isBackgroundLaunch
    }

    @MainActor
    static func handleReopen() {
        suppressInitialPresentation = false

        guard let window = NSApp.windows.first(where: { $0.identifier == identifier }) else {
            return
        }

        window.deminiaturize(nil)
        window.alphaValue = 1
        window.makeKeyAndOrderFront(nil)
    }

    @MainActor
    static func configure(_ window: NSWindow) {
        window.identifier = identifier
        window.tabbingMode = .disallowed
        window.minSize = adjustedMinimumSize(for: window)
        preserveWindowDuringFileOperations(window)

        let windowID = ObjectIdentifier(window)
        guard !fittedWindowIDs.contains(windowID) else {
            return
        }

        fittedWindowIDs.insert(windowID)
        expandWindowIfNeeded(window)

        if suppressInitialPresentation {
            window.alphaValue = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                finishInitialPresentation(of: window)
            }
        }
    }

    @MainActor
    private static func preserveWindowDuringFileOperations(_ window: NSWindow) {
        guard !(window.delegate is MainWindowCloseDelegate) else { return }
        let delegate = MainWindowCloseDelegate(forwardingTo: window.delegate)
        objc_setAssociatedObject(window, &closeDelegateAssociation, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        window.delegate = delegate
    }

    @MainActor
    static func show(openWindow: OpenWindowAction, section: CleanMacSection? = nil) {
        suppressInitialPresentation = false
        if let section {
            UserDefaults.standard.set(section.rawValue, forKey: CleanMacPreferenceKeys.requestedSection)
        }

        if let existingWindow = NSApp.windows.first(where: { $0.identifier == identifier }) {
            existingWindow.deminiaturize(nil)
            existingWindow.alphaValue = 1
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }

    @MainActor
    private static func finishInitialPresentation(of window: NSWindow) {
        if suppressInitialPresentation && !NSApp.isActive {
            window.orderOut(nil)
        }
        window.alphaValue = 1
    }

    @MainActor
    private static func adjustedMinimumSize(for window: NSWindow) -> NSSize {
        guard let visibleFrame = window.screen?.visibleFrame else {
            return minimumSize
        }

        return NSSize(
            width: min(minimumSize.width, visibleFrame.width),
            height: min(minimumSize.height, visibleFrame.height)
        )
    }

    @MainActor
    private static func expandWindowIfNeeded(_ window: NSWindow) {
        let visibleFrame = window.screen?.visibleFrame
        let targetWidth = min(preferredInitialSize.width, visibleFrame?.width ?? preferredInitialSize.width)
        let targetHeight = min(preferredInitialSize.height, visibleFrame?.height ?? preferredInitialSize.height)

        guard window.frame.width < targetWidth || window.frame.height < targetHeight else {
            return
        }

        let oldMaxY = window.frame.maxY
        var frame = window.frame
        frame.size.width = max(frame.width, targetWidth)
        frame.size.height = max(frame.height, targetHeight)
        frame.origin.y = oldMaxY - frame.height

        if let visibleFrame {
            frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
            frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - frame.height)
        }

        window.setFrame(frame, display: true)
    }
}

/// Keeps the SwiftUI window and its operation state alive when the user closes
/// it during a file mutation. All other delegate behavior stays with SwiftUI.
@MainActor
private final class MainWindowCloseDelegate: NSObject, NSWindowDelegate {
    private weak var forwardedDelegate: (any NSWindowDelegate)?

    init(forwardingTo delegate: (any NSWindowDelegate)?) {
        forwardedDelegate = delegate
        super.init()
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if UserDefaults.standard.bool(forKey: CleanMacPreferenceKeys.fileOperationInProgress) {
            sender.orderOut(nil)
            return false
        }
        return forwardedDelegate?.windowShouldClose?(sender) ?? true
    }

    override func responds(to selector: Selector!) -> Bool {
        super.responds(to: selector) || forwardedDelegate?.responds(to: selector) == true
    }

    override func forwardingTarget(for selector: Selector!) -> Any? {
        if let forwardedDelegate, forwardedDelegate.responds(to: selector) {
            return forwardedDelegate
        }
        return super.forwardingTarget(for: selector)
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
