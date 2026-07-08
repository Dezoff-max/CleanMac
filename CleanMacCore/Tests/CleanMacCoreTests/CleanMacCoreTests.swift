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
}
