import Foundation

public enum CleanupCategory: String, CaseIterable, Codable, Identifiable, Sendable {
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

public enum CleanupScanReason: String, Equatable, Sendable {
    case applicationCache
    case browserCache
    case nodePackageCache
    case swiftPackageCache
    case staleLog
    case rotatedLog
    case staleTemporary
    case trashItem
    case largeDownload
    case oldDownload
    case installerArchive
    case xcodeBuildData
}

public struct CleanupScanOptions: Equatable, Sendable {
    public var maxItemsPerCategory: Int
    public var maxDescendantsPerItem: Int
    public var largeDownloadThresholdBytes: Int64
    public var staleDownloadAge: TimeInterval
    public var staleLogAge: TimeInterval
    public var staleTemporaryAge: TimeInterval

    public init(
        maxItemsPerCategory: Int = 80,
        maxDescendantsPerItem: Int = 2_000,
        largeDownloadThresholdBytes: Int64 = 100 * 1024 * 1024,
        staleDownloadAge: TimeInterval = 30 * 24 * 60 * 60,
        staleLogAge: TimeInterval = 7 * 24 * 60 * 60,
        staleTemporaryAge: TimeInterval = 24 * 60 * 60
    ) {
        self.maxItemsPerCategory = max(1, maxItemsPerCategory)
        self.maxDescendantsPerItem = max(1, maxDescendantsPerItem)
        self.largeDownloadThresholdBytes = max(1, largeDownloadThresholdBytes)
        self.staleDownloadAge = max(0, staleDownloadAge)
        self.staleLogAge = max(0, staleLogAge)
        self.staleTemporaryAge = max(0, staleTemporaryAge)
    }
}

public enum CleanupScanProgressPhase: String, Sendable {
    case preparing
    case scanning
    case measuring
    case summarizing
    case completed
}

public struct CleanupScanProgress: Equatable, Sendable {
    public let phase: CleanupScanProgressPhase
    public let currentCategory: CleanupCategory?
    public let currentPath: String?
    public let completedCategoryCount: Int
    public let totalCategoryCount: Int
    public let currentCategoryItemCount: Int
    public let scannedItemCount: Int
    public let totalSizeBytes: Int64
    public let currentCategoryProgress: Double

    public init(
        phase: CleanupScanProgressPhase,
        currentCategory: CleanupCategory?,
        currentPath: String?,
        completedCategoryCount: Int,
        totalCategoryCount: Int,
        currentCategoryItemCount: Int,
        scannedItemCount: Int,
        totalSizeBytes: Int64,
        currentCategoryProgress: Double
    ) {
        self.phase = phase
        self.currentCategory = currentCategory
        self.currentPath = currentPath
        self.completedCategoryCount = max(0, completedCategoryCount)
        self.totalCategoryCount = max(0, totalCategoryCount)
        self.currentCategoryItemCount = max(0, currentCategoryItemCount)
        self.scannedItemCount = max(0, scannedItemCount)
        self.totalSizeBytes = max(0, totalSizeBytes)
        self.currentCategoryProgress = min(max(currentCategoryProgress, 0), 1)
    }

    public var fractionComplete: Double {
        guard totalCategoryCount > 0 else {
            return phase == .completed ? 1 : 0
        }

        if phase == .completed {
            return 1
        }

        let categoryUnits = Double(completedCategoryCount) + currentCategoryProgress
        let rawProgress = categoryUnits / Double(totalCategoryCount)
        return min(max(rawProgress, 0), 0.99)
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
    public let reasons: [CleanupScanReason]

    public init(
        id: String,
        category: CleanupCategory,
        path: String,
        displayName: String,
        sizeBytes: Int64,
        isDirectory: Bool,
        isSizeEstimate: Bool,
        modifiedAt: Date?,
        risk: CleanupRiskLevel,
        reasons: [CleanupScanReason] = []
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
        self.reasons = reasons
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
