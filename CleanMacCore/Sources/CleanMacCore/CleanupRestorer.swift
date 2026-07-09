import Foundation

public struct CleanupRestorer {
    public typealias MoveHandler = (URL, URL) throws -> Void

    private let fileManager: FileManager
    private let moveHandler: MoveHandler

    public init(fileManager: FileManager = .default, moveHandler: MoveHandler? = nil) {
        self.fileManager = fileManager
        if let moveHandler {
            self.moveHandler = moveHandler
        } else {
            self.moveHandler = { source, destination in
                try fileManager.moveItem(at: source, to: destination)
            }
        }
    }

    public func restore(movedItems: [CleanupMovedItem]) -> CleanupRestoreReport {
        var restoredItems: [CleanupRestoredItem] = []
        var failedItems: [CleanupRestoreFailedItem] = []

        for movedItem in movedItems {
            let result = restoreSingle(movedItem)
            switch result {
            case .success(let restoredItem):
                restoredItems.append(restoredItem)
            case .failure(let failedItem):
                failedItems.append(failedItem)
            }
        }

        return CleanupRestoreReport(
            completedAt: Date(),
            restoredItems: restoredItems,
            failedItems: failedItems
        )
    }

    private func restoreSingle(_ movedItem: CleanupMovedItem) -> RestoreAttempt {
        guard let trashedPath = movedItem.trashedPath, !trashedPath.isEmpty else {
            return .failure(failure(
                movedItem,
                reason: .missingTrashPath,
                message: "Missing Trash location for this item."
            ))
        }

        let trashedURL = URL(fileURLWithPath: trashedPath)
        let destinationURL = URL(fileURLWithPath: movedItem.item.originalPath)
        let destinationParentURL = destinationURL.deletingLastPathComponent()

        guard fileManager.fileExists(atPath: trashedURL.path) else {
            return .failure(failure(
                movedItem,
                reason: .missingTrashItem,
                message: "The item is no longer available in Trash."
            ))
        }

        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            return .failure(failure(
                movedItem,
                reason: .destinationExists,
                message: "The original location is already occupied."
            ))
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: destinationParentURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .failure(failure(
                movedItem,
                reason: .missingOriginalParent,
                message: "The original parent folder is not available."
            ))
        }

        do {
            try moveHandler(trashedURL, destinationURL)
            return .success(CleanupRestoredItem(
                movedItem: movedItem,
                restoredPath: destinationURL.path
            ))
        } catch {
            return .failure(failure(
                movedItem,
                reason: .moveFailed,
                message: error.localizedDescription
            ))
        }
    }

    private func failure(
        _ movedItem: CleanupMovedItem,
        reason: CleanupRestoreFailureReason,
        message: String
    ) -> CleanupRestoreFailedItem {
        CleanupRestoreFailedItem(
            movedItem: movedItem,
            reason: reason,
            message: message
        )
    }

    private enum RestoreAttempt {
        case success(CleanupRestoredItem)
        case failure(CleanupRestoreFailedItem)
    }
}
