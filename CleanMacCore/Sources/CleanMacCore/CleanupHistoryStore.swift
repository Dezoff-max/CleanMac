import Foundation

public enum CleanupHistoryStatus: String, Codable, Sendable {
    case inTrash
    case restored
    case restoreFailed
}

public struct CleanupHistoryRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let category: CleanupCategory
    public let originalPath: String
    public let trashedPath: String?
    public let movedAt: Date
    public let sizeBytes: Int64
    public private(set) var status: CleanupHistoryStatus
    public private(set) var restoredAt: Date?
    public private(set) var failureReason: CleanupRestoreFailureReason?

    public init(
        id: UUID = UUID(),
        category: CleanupCategory,
        originalPath: String,
        trashedPath: String?,
        movedAt: Date,
        sizeBytes: Int64,
        status: CleanupHistoryStatus = .inTrash,
        restoredAt: Date? = nil,
        failureReason: CleanupRestoreFailureReason? = nil
    ) {
        self.id = id
        self.category = category
        self.originalPath = originalPath
        self.trashedPath = trashedPath
        self.movedAt = movedAt
        self.sizeBytes = max(0, sizeBytes)
        self.status = status
        self.restoredAt = restoredAt
        self.failureReason = failureReason
    }

    public init(movedItem: CleanupMovedItem, movedAt: Date, id: UUID = UUID()) {
        self.init(
            id: id,
            category: movedItem.item.scanItem.category,
            originalPath: movedItem.item.originalPath,
            trashedPath: movedItem.trashedPath,
            movedAt: movedAt,
            sizeBytes: movedItem.item.scanItem.sizeBytes
        )
    }

    public mutating func markRestored(at date: Date) {
        status = .restored
        restoredAt = date
        failureReason = nil
    }

    public mutating func markRestoreFailed(reason: CleanupRestoreFailureReason) {
        status = .restoreFailed
        restoredAt = nil
        failureReason = reason
    }
}

public struct CleanupHistoryStore: Sendable {
    public static let defaultMaximumRecordCount = 100

    private static let schemaVersion = 1
    private static let maximumFileSizeBytes = 1_048_576

    private let fileURL: URL
    private let maximumRecordCount: Int

    public init(
        fileManager: FileManager = .default,
        maximumRecordCount: Int = CleanupHistoryStore.defaultMaximumRecordCount
    ) {
        let applicationSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser.appending(
            path: "Library/Application Support",
            directoryHint: .isDirectory
        )

        self.init(
            fileURL: applicationSupport
                .appending(path: "CleanMac", directoryHint: .isDirectory)
                .appending(path: "cleanup-history.json"),
            maximumRecordCount: maximumRecordCount
        )
    }

    public init(
        fileURL: URL,
        maximumRecordCount: Int = CleanupHistoryStore.defaultMaximumRecordCount
    ) {
        self.fileURL = fileURL
        self.maximumRecordCount = max(1, maximumRecordCount)
    }

    public func load() -> [CleanupHistoryRecord] {
        do {
            let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true,
                  let fileSize = values.fileSize,
                  fileSize <= Self.maximumFileSizeBytes else {
                return []
            }

            let data = try Data(contentsOf: fileURL)
            let envelope = try JSONDecoder().decode(Envelope.self, from: data)
            guard envelope.schemaVersion == Self.schemaVersion else {
                return []
            }

            return retainedRecords(from: envelope.records)
        } catch {
            return []
        }
    }

    public func save(_ records: [CleanupHistoryRecord]) throws {
        let parentDirectory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: parentDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: parentDirectory.path
        )

        let envelope = Envelope(
            schemaVersion: Self.schemaVersion,
            records: retainedRecords(from: records)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(envelope)
        try data.write(to: fileURL, options: .atomic)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: fileURL.path
        )
    }

    public func upserting(_ records: [CleanupHistoryRecord]) throws -> [CleanupHistoryRecord] {
        let existingRecords = load()
        let existingIDs = Set(existingRecords.map(\.id))
        let updatesByID = Dictionary(records.map { ($0.id, $0) }, uniquingKeysWith: { _, latest in latest })
        var seenNewIDs = Set<UUID>()
        let newRecords = records.filter {
            !existingIDs.contains($0.id) && seenNewIDs.insert($0.id).inserted
        }
        let updatedExistingRecords = existingRecords.map { existing in
            guard let update = updatesByID[existing.id] else {
                return existing
            }

            if existing.status == .restored, update.status != .restored {
                return existing
            }
            return update
        }
        let mergedRecords = retainedRecords(from: newRecords + updatedExistingRecords)
        try save(mergedRecords)
        return mergedRecords
    }

    private func retainedRecords(from records: [CleanupHistoryRecord]) -> [CleanupHistoryRecord] {
        var seenIDs = Set<UUID>()
        var retained: [CleanupHistoryRecord] = []

        for record in records where seenIDs.insert(record.id).inserted {
            retained.append(record)
            if retained.count == maximumRecordCount {
                break
            }
        }

        return retained
    }

    private struct Envelope: Codable {
        let schemaVersion: Int
        let records: [CleanupHistoryRecord]
    }
}
