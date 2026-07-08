import XCTest
@testable import CleanMacCore

final class CleanMacCoreTests: XCTestCase {
    func testStatusIsNotEmpty() {
        XCTAssertFalse(CleanMacCoreInfo.status.isEmpty)
    }

    func testScannerFindsReadOnlyItemsWithoutDeletingFiles() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let temp = root.appending(path: "Temp", directoryHint: .isDirectory)
        let cacheFolder = home.appending(path: "Library/Caches/TestApp", directoryHint: .isDirectory)
        let logFolder = home.appending(path: "Library/Logs", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)

        let cacheFile = cacheFolder.appending(path: "cache.bin")
        let logFile = logFolder.appending(path: "cleanmac.log")
        let tempFile = temp.appending(path: "scratch.tmp")

        try writeBytes(count: 128, to: cacheFile)
        try writeBytes(count: 64, to: logFile)
        try writeBytes(count: 32, to: tempFile)

        let scanner = CleanupScanner(homeDirectory: home, temporaryDirectory: temp)
        let report = scanner.scan(
            categories: [.userCaches, .logs, .temporaryFiles],
            options: CleanupScanOptions(maxItemsPerCategory: 10, maxDescendantsPerItem: 50)
        )

        XCTAssertEqual(report.summaries.count, 3)
        let scannedPaths = Set(report.items.map { canonicalPath($0.path) })
        let scannedPathList = report.items.map(\.path).joined(separator: "\n")
        XCTAssertTrue(scannedPaths.contains(canonicalPath(cacheFolder.path)), scannedPathList)
        XCTAssertTrue(scannedPaths.contains(canonicalPath(logFile.path)), scannedPathList)
        XCTAssertTrue(scannedPaths.contains(canonicalPath(tempFile.path)), scannedPathList)
        XCTAssertGreaterThan(report.totalSizeBytes, 0)

        XCTAssertTrue(FileManager.default.fileExists(atPath: cacheFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: logFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempFile.path))
    }

    func testScannerReportsMissingCategoryAsUnavailableWithoutThrowing() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let scanner = CleanupScanner(homeDirectory: root, temporaryDirectory: root.appending(path: "MissingTemp"))
        let report = scanner.scan(categories: [.xcodeDerivedData])

        XCTAssertEqual(report.items.count, 0)
        XCTAssertEqual(report.issues.count, 0)
        XCTAssertEqual(report.summaries.first?.category, .xcodeDerivedData)
        XCTAssertEqual(report.summaries.first?.isAvailable, false)
    }

    func testCleanupPlannerAcceptsOnlyAllowlistedChildPaths() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let cacheFolder = home.appending(path: "Library/Caches/TestApp", directoryHint: .isDirectory)
        let outsideFile = root.appending(path: "outside.log")
        let cacheRoot = home.appending(path: "Library/Caches", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        try writeBytes(count: 10, to: outsideFile)

        let accepted = makeScanItem(category: .userCaches, path: cacheFolder.path)
        let outside = makeScanItem(category: .userCaches, path: outsideFile.path)
        let rootItem = makeScanItem(category: .userCaches, path: cacheRoot.path)

        let planner = CleanupPlanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let plan = planner.plan(for: [accepted, outside, rootItem])

        XCTAssertEqual(plan.items.map(\.id), [accepted.id])
        XCTAssertEqual(plan.rejectedItems.count, 2)
        XCTAssertEqual(Set(plan.rejectedItems.map(\.reason)), [.outsideAllowedRoot, .categoryRoot])
    }

    func testCleanupExecutorMovesPlannedItemsWithInjectedTrashHandler() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let cacheFolder = home.appending(path: "Library/Caches/TestApp", directoryHint: .isDirectory)
        let trash = root.appending(path: "LocalTrash", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        try writeBytes(count: 32, to: cacheFolder.appending(path: "cache.bin"))

        let item = makeScanItem(category: .userCaches, path: cacheFolder.path, sizeBytes: 32, isDirectory: true)
        let plan = CleanupPlanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
            .plan(for: [item])

        let executor = CleanupExecutor { url in
            let destination = trash.appending(path: url.lastPathComponent)
            try FileManager.default.moveItem(at: url, to: destination)
            return destination
        }

        let report = executor.execute(plan: plan)

        XCTAssertEqual(report.movedItems.count, 1)
        XCTAssertEqual(report.failedItems.count, 0)
        XCTAssertEqual(report.rejectedItems.count, 0)
        XCTAssertEqual(report.totalMovedBytes, 32)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cacheFolder.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: trash.appending(path: "TestApp").path))
    }

    private func makeTemporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "CleanMacCoreTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeBytes(count: Int, to url: URL) throws {
        try Data(repeating: 1, count: count).write(to: url)
    }

    private func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).resolvingSymlinksInPath().path
    }

    private func makeScanItem(
        category: CleanupCategory,
        path: String,
        sizeBytes: Int64 = 1,
        isDirectory: Bool = false
    ) -> CleanupScanItem {
        CleanupScanItem(
            id: "\(category.rawValue):\(path)",
            category: category,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            sizeBytes: sizeBytes,
            isDirectory: isDirectory,
            isSizeEstimate: false,
            modifiedAt: nil,
            risk: category == .downloads || category == .trash || category == .xcodeDerivedData ? .review : .safe
        )
    }
}
