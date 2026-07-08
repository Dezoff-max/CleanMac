import Foundation

public struct CleanupExecutor {
    public typealias TrashHandler = (URL) throws -> URL?

    private let trashHandler: TrashHandler

    public init(fileManager: FileManager = .default, trashHandler: TrashHandler? = nil) {
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

    public func execute(plan: CleanupPlan) -> CleanupExecutionReport {
        var movedItems: [CleanupMovedItem] = []
        var failedItems: [CleanupFailedItem] = []

        for item in plan.items {
            do {
                let trashedURL = try trashHandler(URL(fileURLWithPath: item.originalPath))
                movedItems.append(CleanupMovedItem(item: item, trashedPath: trashedURL?.path))
            } catch {
                failedItems.append(CleanupFailedItem(item: item, message: error.localizedDescription))
            }
        }

        return CleanupExecutionReport(
            completedAt: Date(),
            movedItems: movedItems,
            failedItems: failedItems,
            rejectedItems: plan.rejectedItems
        )
    }
}
