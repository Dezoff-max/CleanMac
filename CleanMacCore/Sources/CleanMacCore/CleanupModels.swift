import Foundation

public enum CleanupCategory: String, CaseIterable, Identifiable, Sendable {
    case userCaches = "user-cache"
    case browserCaches = "browser-cache"
    case nodePackageCaches = "node-cache"
    case swiftPackageBuilds = "swiftpm"
    case logs
    case temporaryFiles = "temp"
    case trash
    case downloads
    case downloadedInstallers = "installers"
    case xcodeDerivedData = "xcode"

    public var id: String { rawValue }
}

public enum CleanupRiskLevel: String, Sendable {
    case safe
    case review
}

public struct CleanupScanOptions: Equatable, Sendable {
    public var maxItemsPerCategory: Int
    public var maxDescendantsPerItem: Int

    public init(maxItemsPerCategory: Int = 80, maxDescendantsPerItem: Int = 2_000) {
        self.maxItemsPerCategory = max(1, maxItemsPerCategory)
        self.maxDescendantsPerItem = max(1, maxDescendantsPerItem)
    }
}

public struct CleanupScanIssue: Equatable, Sendable {
    public let category: CleanupCategory
    public let path: String
    public let message: String

    public init(category: CleanupCategory, path: String, message: String) {
        self.category = category
        self.path = path
        self.message = message
    }
}

public struct CleanupScanItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let category: CleanupCategory
    public let path: String
    public let displayName: String
    public let sizeBytes: Int64
    public let isDirectory: Bool
    public let isSizeEstimate: Bool
    public let modifiedAt: Date?
    public let risk: CleanupRiskLevel

    public init(
        id: String,
        category: CleanupCategory,
        path: String,
        displayName: String,
        sizeBytes: Int64,
        isDirectory: Bool,
        isSizeEstimate: Bool,
        modifiedAt: Date?,
        risk: CleanupRiskLevel
    ) {
        self.id = id
        self.category = category
        self.path = path
        self.displayName = displayName
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
        self.isSizeEstimate = isSizeEstimate
        self.modifiedAt = modifiedAt
        self.risk = risk
    }
}

public struct CleanupCategorySummary: Equatable, Sendable {
    public let category: CleanupCategory
    public let scannedPath: String
    public let itemCount: Int
    public let totalSizeBytes: Int64
    public let isAvailable: Bool

    public init(
        category: CleanupCategory,
        scannedPath: String,
        itemCount: Int,
        totalSizeBytes: Int64,
        isAvailable: Bool
    ) {
        self.category = category
        self.scannedPath = scannedPath
        self.itemCount = itemCount
        self.totalSizeBytes = totalSizeBytes
        self.isAvailable = isAvailable
    }
}

public struct CleanupScanReport: Equatable, Sendable {
    public let scannedAt: Date
    public let durationSeconds: TimeInterval
    public let items: [CleanupScanItem]
    public let summaries: [CleanupCategorySummary]
    public let issues: [CleanupScanIssue]

    public init(
        scannedAt: Date,
        durationSeconds: TimeInterval,
        items: [CleanupScanItem],
        summaries: [CleanupCategorySummary],
        issues: [CleanupScanIssue]
    ) {
        self.scannedAt = scannedAt
        self.durationSeconds = durationSeconds
        self.items = items
        self.summaries = summaries
        self.issues = issues
    }

    public var totalSizeBytes: Int64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }
}
