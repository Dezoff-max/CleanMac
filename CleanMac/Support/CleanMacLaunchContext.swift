import AppKit
import Carbon

enum CleanMacLaunchContext {
    /// An LSUIElement app can still be inactive during an ordinary Finder
    /// launch. Only an explicit system launch reason should hide its window.
    static func isBackgroundLaunch(_ event: NSAppleEventDescriptor?) -> Bool {
        guard let event,
              event.eventClass == AEEventClass(kCoreEventClass),
              event.eventID == AEEventID(kAEOpenApplication),
              let reason = event.paramDescriptor(forKeyword: AEKeyword(keyAEPropData))?.enumCodeValue
        else {
            return false
        }

        return reason == OSType(keyAELaunchedAsLogInItem)
            || reason == OSType(keyAELaunchedAsServiceItem)
    }
}
