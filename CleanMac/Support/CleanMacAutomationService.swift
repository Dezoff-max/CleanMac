import CoreServices
import Foundation

nonisolated enum FinderAutomationPermission: Equatable, Sendable {
    case granted
    case notDetermined
    case denied
    case targetNotRunning
    case unavailable
}

enum CleanMacAutomationService {
    nonisolated private static let finderBundleIdentifier = "com.apple.finder"

    static func checkFinderPermission() async -> FinderAutomationPermission {
        await Task.detached(priority: .utility) {
            determineFinderPermission(askUserIfNeeded: false)
        }.value
    }

    static func requestFinderPermission() async -> FinderAutomationPermission {
        await Task.detached(priority: .userInitiated) {
            determineFinderPermission(askUserIfNeeded: true)
        }.value
    }

    static func revealInFinder(_ url: URL) async -> Bool {
        await Task.detached(priority: .userInitiated) {
            guard determineFinderPermission(askUserIfNeeded: false) == .granted else {
                return false
            }

            return sendFinderEvent(
                eventID: kAEMakeObjectsVisible,
                directObject: NSAppleEventDescriptor(fileURL: url)
            ) && sendFinderEvent(eventID: kAEActivate)
        }.value
    }

    nonisolated private static func determineFinderPermission(
        askUserIfNeeded: Bool
    ) -> FinderAutomationPermission {
        let target = NSAppleEventDescriptor(bundleIdentifier: finderBundleIdentifier)
        guard let targetDescriptor = target.aeDesc else {
            return .unavailable
        }

        let status = AEDeterminePermissionToAutomateTarget(
            targetDescriptor,
            typeWildCard,
            typeWildCard,
            askUserIfNeeded
        )

        switch status {
        case noErr:
            return .granted
        case OSStatus(errAEEventWouldRequireUserConsent):
            return .notDetermined
        case OSStatus(errAEEventNotPermitted):
            return .denied
        case OSStatus(procNotFound):
            return .targetNotRunning
        case OSStatus(errAETargetAddressNotPermitted):
            return .unavailable
        default:
            return .unavailable
        }
    }

    nonisolated private static func sendFinderEvent(
        eventID: AEEventID,
        directObject: NSAppleEventDescriptor? = nil
    ) -> Bool {
        let target = NSAppleEventDescriptor(bundleIdentifier: finderBundleIdentifier)
        let event = NSAppleEventDescriptor(
            eventClass: kAEMiscStandards,
            eventID: eventID,
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )

        if let directObject {
            event.setParam(directObject, forKeyword: keyDirectObject)
        }

        let noPermissionPrompt = NSAppleEventDescriptor.SendOptions(
            rawValue: UInt(kAEDoNotPromptForUserConsent)
        )

        do {
            _ = try event.sendEvent(
                options: [.waitForReply, .neverInteract, noPermissionPrompt],
                timeout: 5
            )
            return true
        } catch {
            return false
        }
    }
}
