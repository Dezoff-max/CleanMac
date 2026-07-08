import Foundation

public struct CleanupScanner {
    private let fileManager: FileManager
    private let rootResolver: CleanupRootResolver

    private let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isRegularFileKey,
        .fileSizeKey,
        .fileAllocatedSizeKey,
        .totalFileAllocatedSizeKey,
        .contentModificationDateKey,
        .isPackageKey
    ]

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

    public func scan(
        categories: [CleanupCategory] = CleanupCategory.allCases,
        options: CleanupScanOptions = CleanupScanOptions()
    ) -> CleanupScanReport {
        let startedAt = Date()
        var allItems: [CleanupScanItem] = []
        var summaries: [CleanupCategorySummary] = []
        var issues: [CleanupScanIssue] = []

        for category in categories {
            let result = scanCategory(category, options: options)
            allItems.append(contentsOf: result.items)
            summaries.append(result.summary)
            issues.append(contentsOf: result.issues)
        }

        let sortedItems = allItems.sorted {
            if $0.sizeBytes == $1.sizeBytes {
                return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
            }
            return $0.sizeBytes > $1.sizeBytes
        }

        return CleanupScanReport(
            scannedAt: startedAt,
            durationSeconds: Date().timeIntervalSince(startedAt),
            items: sortedItems,
            summaries: summaries,
            issues: issues
        )
    }

    private func scanCategory(
        _ category: CleanupCategory,
        options: CleanupScanOptions
    ) -> (items: [CleanupScanItem], summary: CleanupCategorySummary, issues: [CleanupScanIssue]) {
        let rootURL = rootURL(for: category)
        let rootPath = rootURL.path

        guard fileManager.fileExists(atPath: rootPath) else {
            return (
                [],
                CleanupCategorySummary(
                    category: category,
                    scannedPath: rootPath,
                    itemCount: 0,
                    totalSizeBytes: 0,
                    isAvailable: false
                ),
                []
            )
        }

        let childURLs: [URL]
        do {
            childURLs = try fileManager.contentsOfDirectory(
                at: rootURL,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsPackageDescendants]
            )
        } catch {
            let issue = CleanupScanIssue(
                category: category,
                path: rootPath,
                message: error.localizedDescription
            )
            return (
                [],
                CleanupCategorySummary(
                    category: category,
                    scannedPath: rootPath,
                    itemCount: 0,
                    totalSizeBytes: 0,
                    isAvailable: true
                ),
                [issue]
            )
        }

        let items = childURLs
            .prefix(options.maxItemsPerCategory)
            .compactMap { item(for: $0, category: category, options: options) }
            .sorted {
                if $0.sizeBytes == $1.sizeBytes {
                    return $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending
                }
                return $0.sizeBytes > $1.sizeBytes
            }

        let totalSizeBytes = items.reduce(0) { $0 + $1.sizeBytes }

        return (
            items,
            CleanupCategorySummary(
                category: category,
                scannedPath: rootPath,
                itemCount: items.count,
                totalSizeBytes: totalSizeBytes,
                isAvailable: true
            ),
            []
        )
    }

    private func item(
        for url: URL,
        category: CleanupCategory,
        options: CleanupScanOptions
    ) -> CleanupScanItem? {
        let values = try? url.resourceValues(forKeys: resourceKeys)
        let isDirectory = values?.isDirectory == true
        let measuredSize = measureSize(
            at: url,
            isDirectory: isDirectory,
            options: options
        )
        let name = url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent

        return CleanupScanItem(
            id: "\(category.rawValue):\(url.path)",
            category: category,
            path: url.path,
            displayName: name,
            sizeBytes: measuredSize.bytes,
            isDirectory: isDirectory,
            isSizeEstimate: measuredSize.isEstimate,
            modifiedAt: values?.contentModificationDate,
            risk: risk(for: category)
        )
    }

    private func measureSize(
        at url: URL,
        isDirectory: Bool,
        options: CleanupScanOptions
    ) -> (bytes: Int64, isEstimate: Bool) {
        guard isDirectory else {
            let values = try? url.resourceValues(forKeys: resourceKeys)
            return (allocatedSize(from: values), false)
        }

        var bytes = allocatedSize(from: try? url.resourceValues(forKeys: resourceKeys))
        var scannedDescendants = 0
        var isEstimate = false

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return (bytes, true)
        }

        for case let childURL as URL in enumerator {
            scannedDescendants += 1
            if scannedDescendants > options.maxDescendantsPerItem {
                isEstimate = true
                break
            }

            let values = try? childURL.resourceValues(forKeys: resourceKeys)
            bytes += allocatedSize(from: values)
        }

        return (bytes, isEstimate)
    }

    private func allocatedSize(from values: URLResourceValues?) -> Int64 {
        if let totalFileAllocatedSize = values?.totalFileAllocatedSize {
            return Int64(totalFileAllocatedSize)
        }
        if let fileAllocatedSize = values?.fileAllocatedSize {
            return Int64(fileAllocatedSize)
        }
        if let fileSize = values?.fileSize {
            return Int64(fileSize)
        }
        return 0
    }

    private func rootURL(for category: CleanupCategory) -> URL {
        rootResolver.rootURL(for: category)
    }

    private func risk(for category: CleanupCategory) -> CleanupRiskLevel {
        switch category {
        case .userCaches, .logs, .temporaryFiles:
            .safe
        case .trash, .downloads, .xcodeDerivedData:
            .review
        }
    }
}
