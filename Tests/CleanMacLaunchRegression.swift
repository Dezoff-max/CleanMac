import AppKit
import Carbon

@main
private struct CleanMacLaunchRegression {
    static func main() {
        let cases: [(String, NSAppleEventDescriptor?, Bool)] = [
            ("no Apple event still opens the window", nil, false),
            ("ordinary Finder launch opens the window", event(), false),
            ("login item stays in the background", event(reason: keyAELaunchedAsLogInItem), true),
            ("service launch stays in the background", event(reason: keyAELaunchedAsServiceItem), true),
            ("reopen is not a background launch", event(id: kAEReopenApplication, reason: keyAELaunchedAsLogInItem), false),
            ("unrelated event cannot hide the window", event(eventClass: kAEApplicationClass, reason: keyAELaunchedAsLogInItem), false),
            ("unknown launch reason opens the window", event(reason: 0), false)
        ]

        for (name, event, expected) in cases {
            guard CleanMacLaunchContext.isBackgroundLaunch(event) == expected else {
                fatalError("FAIL: \(name)")
            }
            print("PASS: \(name)")
        }
    }

    private static func event(
        eventClass: AEEventClass = AEEventClass(kCoreEventClass),
        id: AEEventID = AEEventID(kAEOpenApplication),
        reason: OSType? = nil
    ) -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(
            eventClass: eventClass,
            eventID: id,
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        if let reason {
            event.setParam(NSAppleEventDescriptor(enumCode: reason), forKeyword: AEKeyword(keyAEPropData))
        }
        return event
    }
}
