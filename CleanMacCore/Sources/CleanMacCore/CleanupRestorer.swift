import Darwin
import Foundation

public struct CleanupRestorer {
    public typealias MoveHandler = (URL, URL) throws -> Void

    private let fileManager: FileManager
    private let moveHandler: MoveHandler
    private let rootResolver: CleanupRootResolver
    private let standardizedTrashRootPath: String
    private let canonicalTrashRootPath: String

    public init(
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory,
        trashDirectory: URL? = nil,
        moveHandler: MoveHandler? = nil
    ) {
        self.fileManager = fileManager
        self.rootResolver = CleanupRootResolver(
            homeDirectory: homeDirectory,
            temporaryDirectory: temporaryDirectory
        )
        let resolvedTrashDirectory = (
            trashDirectory ?? homeDirectory.appending(path: ".Trash", directoryHint: .isDirectory)
        ).standardizedFileURL
        self.standardizedTrashRootPath = resolvedTrashDirectory.path
        self.canonicalTrashRootPath = resolvedTrashDirectory.canonicalPath
        if let moveHandler {
            self.moveHandler = moveHandler
        } else {
            self.moveHandler = Self.secureMove
        }
    }

    public func restore(historyRecords: [CleanupHistoryRecord]) -> CleanupRestoreReport {
        var restoredItems: [CleanupRestoredItem] = []
        var failedItems: [CleanupRestoreFailedItem] = []

        for record in historyRecords {
            switch validatedMovedItem(for: record) {
            case .valid(let movedItem):
                switch restoreSingle(movedItem, pathsAreCanonical: true) {
                case .success(let restoredItem):
                    restoredItems.append(restoredItem)
                case .failure(let failedItem):
                    failedItems.append(failedItem)
                }
            case .invalid(let failedItem):
                failedItems.append(failedItem)
            }
        }

        return CleanupRestoreReport(
            completedAt: Date(),
            restoredItems: restoredItems,
            failedItems: failedItems
        )
    }

    public func restore(movedItems: [CleanupMovedItem]) -> CleanupRestoreReport {
        var restoredItems: [CleanupRestoredItem] = []
        var failedItems: [CleanupRestoreFailedItem] = []

        for movedItem in movedItems {
            let result = restoreSingle(movedItem, pathsAreCanonical: false)
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

    private func restoreSingle(
        _ movedItem: CleanupMovedItem,
        pathsAreCanonical: Bool
    ) -> RestoreAttempt {
        guard let trashedPath = movedItem.trashedPath, !trashedPath.isEmpty else {
            return .failure(failure(
                movedItem,
                reason: .missingTrashPath,
                message: "Missing Trash location for this item."
            ))
        }

        let suppliedTrashedURL = URL(fileURLWithPath: trashedPath)
        let suppliedDestinationURL = URL(fileURLWithPath: movedItem.item.originalPath)
        let rawTrashedURL = pathsAreCanonical
            ? suppliedTrashedURL
            : suppliedTrashedURL.standardizedFileURL
        let rawDestinationURL = pathsAreCanonical
            ? suppliedDestinationURL
            : suppliedDestinationURL.standardizedFileURL
        let rawDestinationParentURL = rawDestinationURL.deletingLastPathComponent()

        guard fileManager.fileExists(atPath: rawTrashedURL.path) else {
            return .failure(failure(
                movedItem,
                reason: .missingTrashItem,
                message: "The item is no longer available in Trash."
            ))
        }

        let trashValues = try? rawTrashedURL.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard trashValues?.isSymbolicLink != true else {
            return .failure(failure(
                movedItem,
                reason: .symbolicLink,
                message: "Symbolic links cannot be restored."
            ))
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(
            atPath: rawDestinationParentURL.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue else {
            return .failure(failure(
                movedItem,
                reason: .missingOriginalParent,
                message: "The original parent folder is not available."
            ))
        }

        let trashedURL = pathsAreCanonical
            ? rawTrashedURL
            : URL(fileURLWithPath: rawTrashedURL.canonicalPath)
        let destinationParentURL = pathsAreCanonical
            ? rawDestinationParentURL
            : URL(fileURLWithPath: rawDestinationParentURL.canonicalPath)
        let destinationURL = destinationParentURL
            .appending(path: rawDestinationURL.lastPathComponent)

        guard !fileManager.fileExists(atPath: destinationURL.path) else {
            return .failure(failure(
                movedItem,
                reason: .destinationExists,
                message: "The original location is already occupied."
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

    private func validatedMovedItem(for record: CleanupHistoryRecord) -> HistoryValidation {
        let unvalidatedItem = movedItem(
            for: record,
            originalPath: record.originalPath,
            trashedPath: record.trashedPath
        )

        guard let trashedPath = record.trashedPath, !trashedPath.isEmpty else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .missingTrashPath,
                message: "Missing Trash location for this item."
            ))
        }

        guard record.originalPath.hasPrefix("/"), trashedPath.hasPrefix("/") else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .outsideAllowedRoot,
                message: "Stored history paths must be absolute."
            ))
        }

        let rawTrashURL = URL(fileURLWithPath: trashedPath).standardizedFileURL
        guard fileManager.fileExists(atPath: rawTrashURL.path) else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .missingTrashItem,
                message: "The item is no longer available in Trash."
            ))
        }

        let trashValues = try? rawTrashURL.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard trashValues?.isSymbolicLink != true else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .symbolicLink,
                message: "Symbolic links cannot be restored from stored history."
            ))
        }

        let canonicalTrashURL = URL(fileURLWithPath: rawTrashURL.canonicalPath)
        guard rawTrashURL.deletingLastPathComponent().path == standardizedTrashRootPath,
              canonicalTrashURL.deletingLastPathComponent().path == canonicalTrashRootPath else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .outsideTrash,
                message: "Stored item is outside the current user's Trash."
            ))
        }

        let rawOriginalURL = URL(fileURLWithPath: record.originalPath).standardizedFileURL
        let rawOriginalParentURL = rawOriginalURL.deletingLastPathComponent()
        var isOriginalParentDirectory: ObjCBool = false
        guard fileManager.fileExists(
            atPath: rawOriginalParentURL.path,
            isDirectory: &isOriginalParentDirectory
        ), isOriginalParentDirectory.boolValue else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .missingOriginalParent,
                message: "The original parent folder is not available."
            ))
        }

        let canonicalOriginalParentURL = URL(fileURLWithPath: rawOriginalParentURL.canonicalPath)
        let canonicalOriginalPath = canonicalOriginalParentURL
            .appending(path: rawOriginalURL.lastPathComponent)
            .path
        let allowedRootPaths = rootResolver.canonicalRootPaths(for: record.category)
        guard allowedRootPaths.contains(where: { canonicalOriginalPath.hasPrefix($0 + "/") }) else {
            return .invalid(failure(
                unvalidatedItem,
                reason: .outsideAllowedRoot,
                message: "Stored destination is outside the allowed cleanup root."
            ))
        }

        return .valid(movedItem(
            for: record,
            originalPath: canonicalOriginalPath,
            trashedPath: canonicalTrashURL.path
        ))
    }

    private func movedItem(
        for record: CleanupHistoryRecord,
        originalPath: String,
        trashedPath: String?
    ) -> CleanupMovedItem {
        let sourceURL = trashedPath.map(URL.init(fileURLWithPath:))
        let isDirectory: Bool
        if let sourceURL,
           let values = try? sourceURL.resourceValues(forKeys: [.isDirectoryKey]) {
            isDirectory = values.isDirectory == true
        } else {
            isDirectory = false
        }
        let displayName = URL(fileURLWithPath: originalPath).lastPathComponent
        let scanItem = CleanupScanItem(
            id: "history:\(record.id.uuidString)",
            category: record.category,
            path: originalPath,
            displayName: displayName.isEmpty ? originalPath : displayName,
            sizeBytes: record.sizeBytes,
            isDirectory: isDirectory,
            isSizeEstimate: false,
            modifiedAt: record.movedAt,
            risk: .review
        )

        return CleanupMovedItem(
            item: CleanupPlanItem(scanItem: scanItem, originalPath: originalPath),
            trashedPath: trashedPath
        )
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

    static func secureMove(source: URL, destination: URL) throws {
        let sourceParentURL = source.deletingLastPathComponent()
        let destinationParentURL = destination.deletingLastPathComponent()
        let sourceDirectory = try openDirectory(sourceParentURL)
        defer { close(sourceDirectory) }
        let destinationDirectory = try openDirectory(destinationParentURL)
        defer { close(destinationDirectory) }

        var sourceInfo = stat()
        let sourceStatus = source.lastPathComponent.withCString {
            fstatat(sourceDirectory, $0, &sourceInfo, AT_SYMLINK_NOFOLLOW)
        }
        guard sourceStatus == 0 else {
            throw currentPOSIXError()
        }
        guard (sourceInfo.st_mode & mode_t(S_IFMT)) != mode_t(S_IFLNK) else {
            throw posixError(ELOOP)
        }

        let renameStatus = source.lastPathComponent.withCString { sourceName in
            destination.lastPathComponent.withCString { destinationName in
                renameatx_np(
                    sourceDirectory,
                    sourceName,
                    destinationDirectory,
                    destinationName,
                    UInt32(RENAME_EXCL)
                )
            }
        }
        guard renameStatus == 0 else {
            throw currentPOSIXError()
        }
    }

    private static func openDirectory(_ url: URL) throws -> Int32 {
        let path = url.path
        guard path.hasPrefix("/") else {
            throw posixError(EINVAL)
        }

        var currentDescriptor = Darwin.open(
            "/",
            O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
        )
        guard currentDescriptor >= 0 else {
            throw currentPOSIXError()
        }

        for component in path.split(separator: "/").map(String.init) {
            let nextDescriptor = component.withCString {
                openat(
                    currentDescriptor,
                    $0,
                    O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC
                )
            }
            if nextDescriptor < 0 {
                let error = posixError(
                    errno,
                    context: "Could not open directory component \(component) in \(path)"
                )
                close(currentDescriptor)
                throw error
            }

            close(currentDescriptor)
            currentDescriptor = nextDescriptor
        }

        return currentDescriptor
    }

    private static func currentPOSIXError() -> NSError {
        posixError(errno)
    }

    private static func posixError(_ code: Int32, context: String? = nil) -> NSError {
        let systemMessage = String(cString: strerror(code))
        return NSError(
            domain: NSPOSIXErrorDomain,
            code: Int(code),
            userInfo: [
                NSLocalizedDescriptionKey: context.map { "\($0): \(systemMessage)" } ?? systemMessage
            ]
        )
    }

    private enum RestoreAttempt {
        case success(CleanupRestoredItem)
        case failure(CleanupRestoreFailedItem)
    }

    private enum HistoryValidation {
        case valid(CleanupMovedItem)
        case invalid(CleanupRestoreFailedItem)
    }
}
