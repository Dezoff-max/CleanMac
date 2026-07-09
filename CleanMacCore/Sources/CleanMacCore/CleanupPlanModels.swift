import Foundation

public enum CleanupPlanRejectionReason: String, Sendable {
    case missing
    case outsideAllowedRoot
    case categoryRoot
    case symbolicLink
}

public struct CleanupPlanItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let scanItem: CleanupScanItem
    public let originalPath: String

    public init(scanItem: CleanupScanItem, originalPath: String) {
        self.id = scanItem.id
        self.scanItem = scanItem
        self.originalPath = originalPath
    }
}

public struct CleanupRejectedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let scanItem: CleanupScanItem
    public let reason: CleanupPlanRejectionReason
    public let message: String

    public init(
        scanItem: CleanupScanItem,
        reason: CleanupPlanRejectionReason,
        message: String
    ) {
        self.id = scanItem.id
        self.scanItem = scanItem
        self.reason = reason
        self.message = message
    }
}

public struct CleanupPlan: Equatable, Sendable {
    public let createdAt: Date
    public let items: [CleanupPlanItem]
    public let rejectedItems: [CleanupRejectedItem]

    public init(
        createdAt: Date,
        items: [CleanupPlanItem],
        rejectedItems: [CleanupRejectedItem]
    ) {
        self.createdAt = createdAt
        self.items = items
        self.rejectedItems = rejectedItems
    }

    public var totalSizeBytes: Int64 {
        items.reduce(0) { $0 + $1.scanItem.sizeBytes }
    }
}

public struct CleanupMovedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let item: CleanupPlanItem
    public let trashedPath: String?

    public init(item: CleanupPlanItem, trashedPath: String?) {
        self.id = item.id
        self.item = item
        self.trashedPath = trashedPath
    }
}

public struct CleanupFailedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let item: CleanupPlanItem
    public let message: String

    public init(item: CleanupPlanItem, message: String) {
        self.id = item.id
        self.item = item
        self.message = message
    }
}

public struct CleanupExecutionReport: Equatable, Sendable {
    public let completedAt: Date
    public let movedItems: [CleanupMovedItem]
    public let failedItems: [CleanupFailedItem]
    public let rejectedItems: [CleanupRejectedItem]

    public init(
        completedAt: Date,
        movedItems: [CleanupMovedItem],
        failedItems: [CleanupFailedItem],
        rejectedItems: [CleanupRejectedItem]
    ) {
        self.completedAt = completedAt
        self.movedItems = movedItems
        self.failedItems = failedItems
        self.rejectedItems = rejectedItems
    }

    public var totalMovedBytes: Int64 {
        movedItems.reduce(0) { $0 + $1.item.scanItem.sizeBytes }
    }

    public var hasProblems: Bool {
        !failedItems.isEmpty || !rejectedItems.isEmpty
    }
}

public enum CleanupRestoreFailureReason: String, Sendable {
    case missingTrashPath
    case missingTrashItem
    case destinationExists
    case missingOriginalParent
    case moveFailed
}

public struct CleanupRestoredItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let movedItem: CleanupMovedItem
    public let restoredPath: String

    public init(movedItem: CleanupMovedItem, restoredPath: String) {
        self.id = movedItem.id
        self.movedItem = movedItem
        self.restoredPath = restoredPath
    }
}

public struct CleanupRestoreFailedItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let movedItem: CleanupMovedItem
    public let reason: CleanupRestoreFailureReason
    public let message: String

    public init(
        movedItem: CleanupMovedItem,
        reason: CleanupRestoreFailureReason,
        message: String
    ) {
        self.id = movedItem.id
        self.movedItem = movedItem
        self.reason = reason
        self.message = message
    }
}

public struct CleanupRestoreReport: Equatable, Sendable {
    public let completedAt: Date
    public let restoredItems: [CleanupRestoredItem]
    public let failedItems: [CleanupRestoreFailedItem]

    public init(
        completedAt: Date,
        restoredItems: [CleanupRestoredItem],
        failedItems: [CleanupRestoreFailedItem]
    ) {
        self.completedAt = completedAt
        self.restoredItems = restoredItems
        self.failedItems = failedItems
    }

    public var hasProblems: Bool {
        !failedItems.isEmpty
    }
}
