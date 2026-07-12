import Darwin
import Foundation

public enum DuplicateCleanupRejectionReason: String, Sendable {
    case unknownSelection
    case protectedOriginal
    case missingOriginal
    case missingCopy
    case outsideSelectedRoot
    case symbolicLink
    case changedSinceScan
}

public struct DuplicateCleanupRejectedItem: Identifiable, Sendable {
    public let id: String
    public let path: String
    public let reason: DuplicateCleanupRejectionReason
    public let message: String

    public init(path: String, reason: DuplicateCleanupRejectionReason, message: String) {
        self.id = "\(reason.rawValue):\(path)"
        self.path = path
        self.reason = reason
        self.message = message
    }
}

public struct DuplicateCleanupPlanItem: Identifiable, Sendable {
    public let id: String
    public let groupID: String
    public let copy: DuplicateFile
    public let protectedOriginal: DuplicateFile

    init(groupID: String, copy: DuplicateFile, protectedOriginal: DuplicateFile) {
        self.id = copy.id
        self.groupID = groupID
        self.copy = copy
        self.protectedOriginal = protectedOriginal
    }
}

public struct DuplicateCleanupPlan: Sendable {
    public let rootPath: String
    public let items: [DuplicateCleanupPlanItem]
    public let rejectedItems: [DuplicateCleanupRejectedItem]

    init(
        rootPath: String,
        items: [DuplicateCleanupPlanItem],
        rejectedItems: [DuplicateCleanupRejectedItem]
    ) {
        self.rootPath = rootPath
        self.items = items
        self.rejectedItems = rejectedItems
    }
}

public struct DuplicateCleanupPlanner {
    private let fileManager: FileManager
    private let rootURL: URL

    public init(root: URL, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.rootURL = root.resolvingSymlinksInPath().standardizedFileURL
    }

    public func plan(
        groups: [DuplicateGroup],
        selectedCopyIDs: Set<String>
    ) -> DuplicateCleanupPlan {
        let knownCopies = Dictionary(uniqueKeysWithValues: groups.flatMap { group in
            group.copies.map { ($0.id, (group, $0)) }
        })
        let originalIDs = Set(groups.map(\.original.id))
        var accepted: [DuplicateCleanupPlanItem] = []
        var rejected: [DuplicateCleanupRejectedItem] = []

        for selectedID in selectedCopyIDs.sorted() {
            if originalIDs.contains(selectedID) {
                rejected.append(rejection(
                    path: selectedID,
                    reason: .protectedOriginal,
                    message: "The protected original can never be selected."
                ))
                continue
            }
            guard let (group, copy) = knownCopies[selectedID] else {
                rejected.append(rejection(
                    path: selectedID,
                    reason: .unknownSelection,
                    message: "The selected path is not a scanned duplicate copy."
                ))
                continue
            }
            guard validateOriginal(group.original) else {
                rejected.append(rejection(
                    path: copy.path,
                    reason: .missingOriginal,
                    message: "The protected original is missing or changed."
                ))
                continue
            }
            guard validateCopy(copy) else {
                rejected.append(rejection(
                    path: copy.path,
                    reason: rejectionReason(for: copy),
                    message: "The duplicate copy is unavailable, changed, or outside the selected root."
                ))
                continue
            }
            accepted.append(DuplicateCleanupPlanItem(
                groupID: group.id,
                copy: copy,
                protectedOriginal: group.original
            ))
        }

        return DuplicateCleanupPlan(
            rootPath: rootURL.path,
            items: accepted,
            rejectedItems: rejected
        )
    }

    private func validateOriginal(_ file: DuplicateFile) -> Bool {
        validate(file)
    }

    private func validateCopy(_ file: DuplicateFile) -> Bool {
        validate(file)
    }

    private func validate(_ file: DuplicateFile) -> Bool {
        let url = URL(fileURLWithPath: file.path)
        guard fileManager.fileExists(atPath: url.path),
              isInsideRoot(url),
              !isSymbolicLink(url),
              metadataMatches(file, at: url) else {
            return false
        }
        return true
    }

    private func rejectionReason(for file: DuplicateFile) -> DuplicateCleanupRejectionReason {
        let url = URL(fileURLWithPath: file.path)
        if !fileManager.fileExists(atPath: url.path) {
            return .missingCopy
        }
        if !isInsideRoot(url) {
            return .outsideSelectedRoot
        }
        if isSymbolicLink(url) {
            return .symbolicLink
        }
        return .changedSinceScan
    }

    private func isInsideRoot(_ url: URL) -> Bool {
        let canonicalRoot = rootURL.canonicalPath
        let canonicalPath = url.canonicalPath
        return canonicalPath != canonicalRoot && canonicalPath.hasPrefix(canonicalRoot + "/")
    }

    private func isSymbolicLink(_ url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }

    private func metadataMatches(_ file: DuplicateFile, at url: URL) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]),
        values.isRegularFile == true,
        Int64(values.fileSize ?? -1) == file.sizeBytes,
        file.modifiedAt == nil || values.contentModificationDate == file.modifiedAt else {
            return false
        }

        var fileInfo = stat()
        guard url.path.withCString({ lstat($0, &fileInfo) }) == 0 else {
            return false
        }
        return UInt64(bitPattern: Int64(fileInfo.st_dev)) == file.deviceID
            && UInt64(fileInfo.st_ino) == file.inode
    }

    private func rejection(
        path: String,
        reason: DuplicateCleanupRejectionReason,
        message: String
    ) -> DuplicateCleanupRejectedItem {
        DuplicateCleanupRejectedItem(path: path, reason: reason, message: message)
    }
}

public struct DuplicateMovedItem: Identifiable, Sendable {
    public let id: String
    public let item: DuplicateCleanupPlanItem
    public let trashedPath: String?

    public init(item: DuplicateCleanupPlanItem, trashedPath: String?) {
        self.id = item.id
        self.item = item
        self.trashedPath = trashedPath
    }
}

public struct DuplicateCleanupFailedItem: Identifiable, Sendable {
    public let id: String
    public let item: DuplicateCleanupPlanItem
    public let message: String

    public init(item: DuplicateCleanupPlanItem, message: String) {
        self.id = item.id
        self.item = item
        self.message = message
    }
}

public struct DuplicateCleanupReport: Sendable {
    public let completedAt: Date
    public let movedItems: [DuplicateMovedItem]
    public let failedItems: [DuplicateCleanupFailedItem]
    public let rejectedItems: [DuplicateCleanupRejectedItem]

    public init(
        completedAt: Date,
        movedItems: [DuplicateMovedItem],
        failedItems: [DuplicateCleanupFailedItem],
        rejectedItems: [DuplicateCleanupRejectedItem]
    ) {
        self.completedAt = completedAt
        self.movedItems = movedItems
        self.failedItems = failedItems
        self.rejectedItems = rejectedItems
    }
}

public struct DuplicateCleanupExecutor {
    public typealias TrashHandler = (URL) throws -> URL?

    private let fileManager: FileManager
    private let trashHandler: TrashHandler

    public init(fileManager: FileManager = .default, trashHandler: TrashHandler? = nil) {
        self.fileManager = fileManager
        if let trashHandler {
            self.trashHandler = trashHandler
        } else {
            self.trashHandler = { url in
                var resultingURL: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
                return resultingURL as URL?
            }
        }
    }

    public func execute(plan: DuplicateCleanupPlan) -> DuplicateCleanupReport {
        var movedItems: [DuplicateMovedItem] = []
        var failedItems: [DuplicateCleanupFailedItem] = []

        for item in plan.items {
            guard fileManager.fileExists(atPath: item.protectedOriginal.path) else {
                failedItems.append(DuplicateCleanupFailedItem(
                    item: item,
                    message: "The protected original disappeared before cleanup."
                ))
                continue
            }
            do {
                let trashedURL = try trashHandler(URL(fileURLWithPath: item.copy.path))
                movedItems.append(DuplicateMovedItem(item: item, trashedPath: trashedURL?.path))
            } catch {
                failedItems.append(DuplicateCleanupFailedItem(item: item, message: error.localizedDescription))
            }
        }

        return DuplicateCleanupReport(
            completedAt: Date(),
            movedItems: movedItems,
            failedItems: failedItems,
            rejectedItems: plan.rejectedItems
        )
    }
}
