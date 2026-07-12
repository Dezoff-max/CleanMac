import Foundation

public struct CleanupPlanner {
    private let fileManager: FileManager
    private let rootResolver: CleanupRootResolver

    public init(
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory
    ) {
        self.fileManager = fileManager
        self.rootResolver = CleanupRootResolver(
            homeDirectory: homeDirectory,
            temporaryDirectory: temporaryDirectory
        )
    }

    public func plan(for items: [CleanupScanItem]) -> CleanupPlan {
        var acceptedItems: [CleanupPlanItem] = []
        var rejectedItems: [CleanupRejectedItem] = []

        for item in items {
            switch validate(item) {
            case .accepted(let planItem):
                acceptedItems.append(planItem)
            case .rejected(let rejectedItem):
                rejectedItems.append(rejectedItem)
            }
        }

        return CleanupPlan(
            createdAt: Date(),
            items: acceptedItems,
            rejectedItems: rejectedItems
        )
    }

    private enum ValidationResult {
        case accepted(CleanupPlanItem)
        case rejected(CleanupRejectedItem)
    }

    private func validate(_ item: CleanupScanItem) -> ValidationResult {
        let url = URL(fileURLWithPath: item.path)

        guard fileManager.fileExists(atPath: url.path) else {
            return .rejected(rejection(
                for: item,
                reason: .missing,
                message: "Path no longer exists."
            ))
        }

        let canonicalPath = url.canonicalPath
        let rootPaths = rootResolver.canonicalRootPaths(for: item.category)

        guard !rootPaths.contains(canonicalPath) else {
            return .rejected(rejection(
                for: item,
                reason: .categoryRoot,
                message: "Category root cannot be cleaned directly."
            ))
        }

        guard rootPaths.contains(where: { canonicalPath.hasPrefix($0 + "/") }) else {
            return .rejected(rejection(
                for: item,
                reason: .outsideAllowedRoot,
                message: "Path is outside the allowed cleanup root."
            ))
        }

        if item.category == .xcodeArchives, url.pathExtension.lowercased() != "xcarchive" {
            return .rejected(rejection(
                for: item,
                reason: .outsideAllowedRoot,
                message: "Only individual Xcode archive bundles can be cleaned."
            ))
        }

        let directChildCategories: Set<CleanupCategory> = [
            .xcodeDeviceSupport,
            .xcodePreviews,
            .xcodeSimulatorData
        ]
        if directChildCategories.contains(item.category) {
            let canonicalParentPath = url.deletingLastPathComponent().canonicalPath
            guard rootPaths.contains(canonicalParentPath) else {
                return .rejected(rejection(
                    for: item,
                    reason: .outsideAllowedRoot,
                    message: "Only direct children of this cleanup root can be cleaned."
                ))
            }
        }

        let values = try? url.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard values?.isSymbolicLink != true else {
            return .rejected(rejection(
                for: item,
                reason: .symbolicLink,
                message: "Symbolic links require manual review."
            ))
        }

        return .accepted(CleanupPlanItem(scanItem: item, originalPath: canonicalPath))
    }

    private func rejection(
        for item: CleanupScanItem,
        reason: CleanupPlanRejectionReason,
        message: String
    ) -> CleanupRejectedItem {
        CleanupRejectedItem(scanItem: item, reason: reason, message: message)
    }
}
