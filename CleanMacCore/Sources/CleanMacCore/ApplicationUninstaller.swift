import Foundation

public enum InstalledApplicationLocation: String, Sendable {
    case shared
    case user
}

public enum ApplicationLeftoverKind: String, CaseIterable, Sendable {
    case cache
    case preferences
    case savedApplicationState
    case logs
    case applicationSupport
    case container
    case groupContainer
    case httpStorage
    case webKit
    case cookies
    case applicationScripts
    case launchAgent
}

public enum ApplicationRemovalMode: String, CaseIterable, Sendable {
    case moveToTrash
    case deletePermanently
}

public struct ApplicationLeftover: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: ApplicationLeftoverKind
    public let path: String
    public let sizeBytes: Int64
    public let isSizeEstimate: Bool

    public init(
        kind: ApplicationLeftoverKind,
        path: String,
        sizeBytes: Int64,
        isSizeEstimate: Bool
    ) {
        self.id = path
        self.kind = kind
        self.path = path
        self.sizeBytes = sizeBytes
        self.isSizeEstimate = isSizeEstimate
    }
}

public struct InstalledApplication: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let bundleIdentifier: String
    public let path: String
    public let sizeBytes: Int64
    public let isSizeEstimate: Bool
    public let location: InstalledApplicationLocation
    public let leftovers: [ApplicationLeftover]

    public init(
        name: String,
        bundleIdentifier: String,
        path: String,
        sizeBytes: Int64,
        isSizeEstimate: Bool,
        location: InstalledApplicationLocation,
        leftovers: [ApplicationLeftover]
    ) {
        self.id = path
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.path = path
        self.sizeBytes = sizeBytes
        self.isSizeEstimate = isSizeEstimate
        self.location = location
        self.leftovers = leftovers
    }

    public var totalReviewSizeBytes: Int64 {
        sizeBytes + leftovers.reduce(0) { $0 + $1.sizeBytes }
    }
}

public struct InstalledApplicationScanIssue: Identifiable, Equatable, Sendable {
    public let id: String
    public let path: String
    public let message: String

    public init(path: String, message: String) {
        self.id = path
        self.path = path
        self.message = message
    }
}

public struct InstalledApplicationScanReport: Equatable, Sendable {
    public let applications: [InstalledApplication]
    public let issues: [InstalledApplicationScanIssue]

    public init(
        applications: [InstalledApplication],
        issues: [InstalledApplicationScanIssue]
    ) {
        self.applications = applications
        self.issues = issues
    }
}

public struct InstalledApplicationScanner {
    private let fileManager: FileManager
    private let applicationDirectories: [URL]
    private let homeDirectory: URL
    private let excludedBundleIdentifiers: Set<String>
    private let excludedApplicationPaths: Set<String>
    private let maxDescendantsPerItem: Int

    public init(
        fileManager: FileManager = .default,
        applicationDirectories: [URL]? = nil,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        excludedBundleIdentifiers: Set<String> = [],
        excludedApplicationPaths: Set<String> = [],
        maxDescendantsPerItem: Int = 25_000
    ) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory
        self.applicationDirectories = applicationDirectories ?? [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            homeDirectory.appending(path: "Applications", directoryHint: .isDirectory)
        ]
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
        self.excludedApplicationPaths = Set(excludedApplicationPaths.map(Self.canonicalPath))
        self.maxDescendantsPerItem = max(1, maxDescendantsPerItem)
    }

    public func scan() -> InstalledApplicationScanReport {
        var applications: [InstalledApplication] = []
        var issues: [InstalledApplicationScanIssue] = []

        for (index, directory) in applicationDirectories.enumerated() {
            guard fileManager.fileExists(atPath: directory.path) else {
                continue
            }

            let childURLs: [URL]
            do {
                childURLs = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                issues.append(InstalledApplicationScanIssue(
                    path: directory.path,
                    message: error.localizedDescription
                ))
                continue
            }

            let location: InstalledApplicationLocation = index == 1 ? .user : .shared
            for url in childURLs where url.pathExtension.lowercased() == "app" {
                guard let application = application(at: url, location: location) else {
                    continue
                }
                applications.append(application)
            }
        }

        let uniqueApplications = Dictionary(
            applications.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        ).values.sorted {
            let nameComparison = $0.name.localizedStandardCompare($1.name)
            return nameComparison == .orderedSame ? $0.path < $1.path : nameComparison == .orderedAscending
        }

        return InstalledApplicationScanReport(
            applications: uniqueApplications,
            issues: issues
        )
    }

    private func application(
        at url: URL,
        location: InstalledApplicationLocation
    ) -> InstalledApplication? {
        guard !isSymbolicLink(url) else {
            return nil
        }

        let canonicalPath = Self.canonicalPath(url.path)
        guard !excludedApplicationPaths.contains(canonicalPath),
              let metadata = Self.bundleMetadata(at: url),
              Self.isSafeBundleIdentifier(metadata.bundleIdentifier),
              !metadata.bundleIdentifier.hasPrefix("com.apple."),
              !excludedBundleIdentifiers.contains(metadata.bundleIdentifier) else {
            return nil
        }

        let appSize = measuredSize(of: url)
        let leftovers = ApplicationLeftoverKind.allCases.compactMap {
            leftover(for: $0, bundleIdentifier: metadata.bundleIdentifier)
        }

        return InstalledApplication(
            name: metadata.name ?? url.deletingPathExtension().lastPathComponent,
            bundleIdentifier: metadata.bundleIdentifier,
            path: canonicalPath,
            sizeBytes: appSize.bytes,
            isSizeEstimate: appSize.isEstimate,
            location: location,
            leftovers: leftovers
        )
    }

    private func leftover(
        for kind: ApplicationLeftoverKind,
        bundleIdentifier: String
    ) -> ApplicationLeftover? {
        let url = Self.leftoverURL(
            for: kind,
            bundleIdentifier: bundleIdentifier,
            homeDirectory: homeDirectory
        )
        guard fileManager.fileExists(atPath: url.path), !isSymbolicLink(url) else {
            return nil
        }

        let size = measuredSize(of: url)
        return ApplicationLeftover(
            kind: kind,
            path: Self.canonicalPath(url.path),
            sizeBytes: size.bytes,
            isSizeEstimate: size.isEstimate
        )
    }

    private func measuredSize(of url: URL) -> (bytes: Int64, isEstimate: Bool) {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey
        ]
        let values = try? url.resourceValues(forKeys: keys)
        guard values?.isDirectory == true else {
            let size = values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0
            return (Int64(size), values == nil)
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return (0, true)
        }

        var bytes: Int64 = 0
        var visited = 0
        var isEstimate = false
        for case let childURL as URL in enumerator {
            visited += 1
            if visited > maxDescendantsPerItem {
                isEstimate = true
                break
            }

            guard let childValues = try? childURL.resourceValues(forKeys: keys) else {
                isEstimate = true
                continue
            }
            if childValues.isDirectory != true {
                bytes += Int64(childValues.totalFileAllocatedSize ?? childValues.fileAllocatedSize ?? 0)
            }
        }
        return (bytes, isEstimate)
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }

    fileprivate static func bundleMetadata(at applicationURL: URL) -> (bundleIdentifier: String, name: String?)? {
        let infoURL = applicationURL.appending(path: "Contents/Info.plist")
        guard let data = try? Data(contentsOf: infoURL),
              let propertyList = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let info = propertyList as? [String: Any],
              let bundleIdentifier = info["CFBundleIdentifier"] as? String else {
            return nil
        }

        let displayName = info["CFBundleDisplayName"] as? String
        let bundleName = info["CFBundleName"] as? String
        return (bundleIdentifier, displayName ?? bundleName)
    }

    fileprivate static func leftoverURL(
        for kind: ApplicationLeftoverKind,
        bundleIdentifier: String,
        homeDirectory: URL
    ) -> URL {
        switch kind {
        case .cache:
            homeDirectory.appending(path: "Library/Caches/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .preferences:
            homeDirectory.appending(path: "Library/Preferences/\(bundleIdentifier).plist")
        case .savedApplicationState:
            homeDirectory.appending(path: "Library/Saved Application State/\(bundleIdentifier).savedState", directoryHint: .isDirectory)
        case .logs:
            homeDirectory.appending(path: "Library/Logs/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .applicationSupport:
            homeDirectory.appending(path: "Library/Application Support/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .container:
            homeDirectory.appending(path: "Library/Containers/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .groupContainer:
            homeDirectory.appending(path: "Library/Group Containers/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .httpStorage:
            homeDirectory.appending(path: "Library/HTTPStorages/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .webKit:
            homeDirectory.appending(path: "Library/WebKit/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .cookies:
            homeDirectory.appending(path: "Library/Cookies/\(bundleIdentifier).binarycookies")
        case .applicationScripts:
            homeDirectory.appending(path: "Library/Application Scripts/\(bundleIdentifier)", directoryHint: .isDirectory)
        case .launchAgent:
            homeDirectory.appending(path: "Library/LaunchAgents/\(bundleIdentifier).plist")
        }
    }

    fileprivate static func isSafeBundleIdentifier(_ value: String) -> Bool {
        guard !value.isEmpty, !value.hasPrefix("."), !value.hasSuffix(".") else {
            return false
        }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-"))
        return value.unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    fileprivate static func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath().path
    }
}

public enum ApplicationRemovalTargetKind: Equatable, Sendable {
    case application
    case leftover(ApplicationLeftoverKind)
}

public struct ApplicationRemovalPlanItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let kind: ApplicationRemovalTargetKind
    public let path: String
    public let sizeBytes: Int64

    public init(
        kind: ApplicationRemovalTargetKind,
        path: String,
        sizeBytes: Int64
    ) {
        self.id = path
        self.kind = kind
        self.path = path
        self.sizeBytes = sizeBytes
    }
}

public enum ApplicationRemovalRejectionReason: String, Sendable {
    case missing
    case invalidApplicationPath
    case forbiddenBundleIdentifier
    case symbolicLink
    case invalidLeftover
}

public struct ApplicationRemovalRejectedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let path: String
    public let reason: ApplicationRemovalRejectionReason
    public let message: String

    public init(path: String, reason: ApplicationRemovalRejectionReason, message: String) {
        self.id = path
        self.path = path
        self.reason = reason
        self.message = message
    }
}

public struct ApplicationRemovalPlan: Equatable, Sendable {
    public let createdAt: Date
    public let application: InstalledApplication
    public let applicationItem: ApplicationRemovalPlanItem?
    public let leftoverItems: [ApplicationRemovalPlanItem]
    public let rejectedItems: [ApplicationRemovalRejectedItem]

    public init(
        createdAt: Date,
        application: InstalledApplication,
        applicationItem: ApplicationRemovalPlanItem?,
        leftoverItems: [ApplicationRemovalPlanItem],
        rejectedItems: [ApplicationRemovalRejectedItem]
    ) {
        self.createdAt = createdAt
        self.application = application
        self.applicationItem = applicationItem
        self.leftoverItems = leftoverItems
        self.rejectedItems = rejectedItems
    }
}

public struct ApplicationRemovalPlanner {
    private let fileManager: FileManager
    private let applicationDirectories: [URL]
    private let homeDirectory: URL
    private let excludedBundleIdentifiers: Set<String>
    private let excludedApplicationPaths: Set<String>

    public init(
        fileManager: FileManager = .default,
        applicationDirectories: [URL]? = nil,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        excludedBundleIdentifiers: Set<String> = [],
        excludedApplicationPaths: Set<String> = []
    ) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory
        self.applicationDirectories = applicationDirectories ?? [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            homeDirectory.appending(path: "Applications", directoryHint: .isDirectory)
        ]
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
        self.excludedApplicationPaths = Set(excludedApplicationPaths.map(InstalledApplicationScanner.canonicalPath))
    }

    public func plan(
        for application: InstalledApplication,
        selectedLeftoverIDs: Set<String>
    ) -> ApplicationRemovalPlan {
        var rejectedItems: [ApplicationRemovalRejectedItem] = []
        let applicationURL = URL(fileURLWithPath: application.path)

        guard fileManager.fileExists(atPath: application.path) else {
            return rejectedPlan(
                application,
                path: application.path,
                reason: .missing,
                message: "The application no longer exists."
            )
        }

        if isSymbolicLink(applicationURL) {
            return rejectedPlan(
                application,
                path: application.path,
                reason: .symbolicLink,
                message: "Symbolic links cannot be removed by the application uninstaller."
            )
        }

        let canonicalApplicationPath = InstalledApplicationScanner.canonicalPath(application.path)
        let allowedParentPaths = Set(applicationDirectories.map {
            InstalledApplicationScanner.canonicalPath($0.path)
        })
        guard applicationURL.pathExtension.lowercased() == "app",
              allowedParentPaths.contains(URL(fileURLWithPath: canonicalApplicationPath).deletingLastPathComponent().path),
              !excludedApplicationPaths.contains(canonicalApplicationPath) else {
            return rejectedPlan(
                application,
                path: application.path,
                reason: .invalidApplicationPath,
                message: "The application is outside the allowed Applications folders."
            )
        }

        guard let metadata = InstalledApplicationScanner.bundleMetadata(at: applicationURL),
              metadata.bundleIdentifier == application.bundleIdentifier,
              InstalledApplicationScanner.isSafeBundleIdentifier(metadata.bundleIdentifier),
              !metadata.bundleIdentifier.hasPrefix("com.apple."),
              !excludedBundleIdentifiers.contains(metadata.bundleIdentifier) else {
            return rejectedPlan(
                application,
                path: application.path,
                reason: .forbiddenBundleIdentifier,
                message: "The application bundle identifier failed the safety check."
            )
        }

        let applicationItem = ApplicationRemovalPlanItem(
            kind: .application,
            path: canonicalApplicationPath,
            sizeBytes: application.sizeBytes
        )
        var leftoverItems: [ApplicationRemovalPlanItem] = []
        let knownLeftoversByID = Dictionary(
            uniqueKeysWithValues: application.leftovers.map { ($0.id, $0) }
        )

        for selectedID in selectedLeftoverIDs.sorted() {
            guard let scannedLeftover = knownLeftoversByID[selectedID] else {
                rejectedItems.append(ApplicationRemovalRejectedItem(
                    path: selectedID,
                    reason: .invalidLeftover,
                    message: "The selected leftover was not part of the application scan."
                ))
                continue
            }

            let expectedURL = InstalledApplicationScanner.leftoverURL(
                for: scannedLeftover.kind,
                bundleIdentifier: metadata.bundleIdentifier,
                homeDirectory: homeDirectory
            )
            guard fileManager.fileExists(atPath: expectedURL.path) else {
                rejectedItems.append(ApplicationRemovalRejectedItem(
                    path: scannedLeftover.path,
                    reason: .missing,
                    message: "The selected leftover no longer exists."
                ))
                continue
            }
            guard !isSymbolicLink(expectedURL) else {
                rejectedItems.append(ApplicationRemovalRejectedItem(
                    path: scannedLeftover.path,
                    reason: .symbolicLink,
                    message: "Symbolic link leftovers require manual review."
                ))
                continue
            }

            let expectedPath = InstalledApplicationScanner.canonicalPath(expectedURL.path)
            guard expectedPath == InstalledApplicationScanner.canonicalPath(scannedLeftover.path) else {
                rejectedItems.append(ApplicationRemovalRejectedItem(
                    path: scannedLeftover.path,
                    reason: .invalidLeftover,
                    message: "The selected leftover path failed the bundle identifier check."
                ))
                continue
            }

            leftoverItems.append(ApplicationRemovalPlanItem(
                kind: .leftover(scannedLeftover.kind),
                path: expectedPath,
                sizeBytes: scannedLeftover.sizeBytes
            ))
        }

        return ApplicationRemovalPlan(
            createdAt: Date(),
            application: application,
            applicationItem: applicationItem,
            leftoverItems: leftoverItems,
            rejectedItems: rejectedItems
        )
    }

    private func rejectedPlan(
        _ application: InstalledApplication,
        path: String,
        reason: ApplicationRemovalRejectionReason,
        message: String
    ) -> ApplicationRemovalPlan {
        ApplicationRemovalPlan(
            createdAt: Date(),
            application: application,
            applicationItem: nil,
            leftoverItems: [],
            rejectedItems: [ApplicationRemovalRejectedItem(path: path, reason: reason, message: message)]
        )
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }
}

public struct ApplicationRemovalMovedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let item: ApplicationRemovalPlanItem
    public let trashedPath: String?

    public init(item: ApplicationRemovalPlanItem, trashedPath: String?) {
        self.id = item.id
        self.item = item
        self.trashedPath = trashedPath
    }
}

public struct ApplicationRemovalFailedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let item: ApplicationRemovalPlanItem
    public let message: String

    public init(item: ApplicationRemovalPlanItem, message: String) {
        self.id = item.id
        self.item = item
        self.message = message
    }
}

public struct ApplicationRemovalReport: Equatable, Sendable {
    public let completedAt: Date
    public let mode: ApplicationRemovalMode
    public let movedItems: [ApplicationRemovalMovedItem]
    public let failedItems: [ApplicationRemovalFailedItem]
    public let rejectedItems: [ApplicationRemovalRejectedItem]

    public init(
        completedAt: Date,
        mode: ApplicationRemovalMode = .moveToTrash,
        movedItems: [ApplicationRemovalMovedItem],
        failedItems: [ApplicationRemovalFailedItem],
        rejectedItems: [ApplicationRemovalRejectedItem]
    ) {
        self.completedAt = completedAt
        self.mode = mode
        self.movedItems = movedItems
        self.failedItems = failedItems
        self.rejectedItems = rejectedItems
    }

    public var applicationMoved: Bool {
        movedItems.contains { $0.item.kind == .application }
    }

    public var totalMovedBytes: Int64 {
        movedItems.reduce(0) { $0 + $1.item.sizeBytes }
    }

    public var hasProblems: Bool {
        !failedItems.isEmpty || !rejectedItems.isEmpty
    }
}

public struct ApplicationRemovalExecutor {
    public typealias TrashHandler = (URL) throws -> URL?
    public typealias PermanentDeleteHandler = (URL) throws -> Void

    private let trashHandler: TrashHandler
    private let permanentDeleteHandler: PermanentDeleteHandler

    public init(
        fileManager: FileManager = .default,
        trashHandler: TrashHandler? = nil,
        permanentDeleteHandler: PermanentDeleteHandler? = nil
    ) {
        if let trashHandler {
            self.trashHandler = trashHandler
        } else {
            self.trashHandler = { url in
                var resultingURL: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
                return resultingURL as URL?
            }
        }

        if let permanentDeleteHandler {
            self.permanentDeleteHandler = permanentDeleteHandler
        } else {
            self.permanentDeleteHandler = { url in
                try fileManager.removeItem(at: url)
            }
        }
    }

    public func execute(
        plan: ApplicationRemovalPlan,
        mode: ApplicationRemovalMode = .moveToTrash
    ) -> ApplicationRemovalReport {
        guard let applicationItem = plan.applicationItem else {
            return ApplicationRemovalReport(
                completedAt: Date(),
                mode: mode,
                movedItems: [],
                failedItems: [],
                rejectedItems: plan.rejectedItems
            )
        }

        var movedItems: [ApplicationRemovalMovedItem] = []
        var failedItems: [ApplicationRemovalFailedItem] = []

        do {
            let trashedURL = try remove(item: applicationItem, mode: mode)
            movedItems.append(ApplicationRemovalMovedItem(
                item: applicationItem,
                trashedPath: trashedURL?.path
            ))
        } catch {
            failedItems.append(ApplicationRemovalFailedItem(
                item: applicationItem,
                message: error.localizedDescription
            ))
            return ApplicationRemovalReport(
                completedAt: Date(),
                mode: mode,
                movedItems: movedItems,
                failedItems: failedItems,
                rejectedItems: plan.rejectedItems
            )
        }

        for leftoverItem in plan.leftoverItems {
            do {
                let trashedURL = try remove(item: leftoverItem, mode: mode)
                movedItems.append(ApplicationRemovalMovedItem(
                    item: leftoverItem,
                    trashedPath: trashedURL?.path
                ))
            } catch {
                failedItems.append(ApplicationRemovalFailedItem(
                    item: leftoverItem,
                    message: error.localizedDescription
                ))
            }
        }

        return ApplicationRemovalReport(
            completedAt: Date(),
            mode: mode,
            movedItems: movedItems,
            failedItems: failedItems,
            rejectedItems: plan.rejectedItems
        )
    }

    private func remove(
        item: ApplicationRemovalPlanItem,
        mode: ApplicationRemovalMode
    ) throws -> URL? {
        let url = URL(fileURLWithPath: item.path)
        switch mode {
        case .moveToTrash:
            return try trashHandler(url)
        case .deletePermanently:
            try permanentDeleteHandler(url)
            return nil
        }
    }
}
