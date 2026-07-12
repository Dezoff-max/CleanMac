import XCTest
@testable import CleanMacCore

final class DiskAnalyzerTests: XCTestCase {
    func testReadOnlyScanBuildsTreeAndFindsLargeFiles() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let documents = root.appending(path: "Documents", directoryHint: .isDirectory)
        let media = root.appending(path: "Media", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: media, withIntermediateDirectories: true)

        let largeVideo = media.appending(path: "Movie.mov")
        let smallDocument = documents.appending(path: "Notes.txt")
        try write(size: 2 * 1024 * 1024, to: largeVideo)
        try write(size: 128 * 1024, to: smallDocument)

        let progressRecorder = DiskProgressRecorder()
        let report = try DiskAnalyzer().scan(
            root: root,
            options: DiskAnalysisOptions(
                minimumLargeFileSizeBytes: 1024 * 1024,
                maximumLargeFiles: 20,
                maximumTreeDepth: 4,
                maximumChildrenPerNode: 8,
                maximumTreeNodes: 100,
                progressInterval: 1
            ),
            progress: progressRecorder.append
        )
        let progressEvents = progressRecorder.events

        XCTAssertGreaterThan(report.root.sizeBytes, 0)
        XCTAssertEqual(Set(report.root.children.filter(\.isDirectory).map(\.name)), ["Documents", "Media"])
        XCTAssertEqual(report.largeFiles.map(\.name), ["Movie.mov"])
        XCTAssertEqual(report.largeFiles.first?.fileType, .video)
        XCTAssertEqual(progressEvents.first?.phase, .preparing)
        XCTAssertEqual(progressEvents.last?.phase, .completed)
        XCTAssertTrue(FileManager.default.fileExists(atPath: largeVideo.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: smallDocument.path))
    }

    func testScanDoesNotFollowSymbolicLinksOutsideRoot() throws {
        let container = try makeRoot()
        defer { try? FileManager.default.removeItem(at: container) }

        let root = container.appending(path: "Root", directoryHint: .isDirectory)
        let outside = container.appending(path: "Outside", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)

        let outsideFile = outside.appending(path: "Outside.mov")
        try write(size: 2 * 1024 * 1024, to: outsideFile)
        try FileManager.default.createSymbolicLink(
            at: root.appending(path: "Outside Link", directoryHint: .isDirectory),
            withDestinationURL: outside
        )

        let report = try DiskAnalyzer().scan(
            root: root,
            options: DiskAnalysisOptions(minimumLargeFileSizeBytes: 1024 * 1024)
        )

        XCTAssertTrue(report.largeFiles.isEmpty)
        XCTAssertEqual(report.root.sizeBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outsideFile.path))
    }

    func testScanCanBeCancelledBeforeEnumeration() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertThrowsError(try DiskAnalyzer().scan(root: root, isCancelled: { true })) { error in
            XCTAssertTrue(error is CancellationError)
        }
    }

    func testTreeBreadthIsBoundedAndRemainderIsAggregated() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        for index in 0..<6 {
            let directory = root.appending(path: "Folder\(index)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try write(size: (index + 1) * 32 * 1024, to: directory.appending(path: "file.bin"))
        }

        let report = try DiskAnalyzer().scan(
            root: root,
            options: DiskAnalysisOptions(
                minimumLargeFileSizeBytes: 10 * 1024 * 1024,
                maximumLargeFiles: 10,
                maximumTreeDepth: 3,
                maximumChildrenPerNode: 3,
                maximumTreeNodes: 100,
                progressInterval: 10
            )
        )

        XCTAssertEqual(report.root.children.count, 3)
        XCTAssertTrue(report.root.children.contains(where: \.isAggregate))
        XCTAssertEqual(report.root.children.reduce(0) { $0 + $1.sizeBytes }, report.root.sizeBytes)
    }

    func testDeepEarlyFolderDoesNotHideLaterRootFolders() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let early = root.appending(path: "A-Early", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: early, withIntermediateDirectories: true)
        for index in 0..<40 {
            let nested = early.appending(path: "Nested\(index)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
            try write(size: 1024, to: nested.appending(path: "small.bin"))
        }

        let later = root.appending(path: "Z-Later", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: later, withIntermediateDirectories: true)
        try write(size: 1024 * 1024, to: later.appending(path: "large.bin"))

        let report = try DiskAnalyzer().scan(
            root: root,
            options: DiskAnalysisOptions(
                minimumLargeFileSizeBytes: 10 * 1024 * 1024,
                maximumLargeFiles: 10,
                maximumTreeDepth: 4,
                maximumChildrenPerNode: 8,
                maximumTreeNodes: 32,
                progressInterval: 10
            )
        )

        XCTAssertTrue(report.root.children.contains { $0.name == "Z-Later" })
    }

    private func makeRoot() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "CleanMac-DiskAnalyzerTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func write(size: Int, to url: URL) throws {
        try Data(repeating: 0x41, count: size).write(to: url, options: .atomic)
    }
}

private final class DiskProgressRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [DiskAnalysisProgress] = []

    var events: [DiskAnalysisProgress] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ event: DiskAnalysisProgress) {
        lock.lock()
        storage.append(event)
        lock.unlock()
    }
}
