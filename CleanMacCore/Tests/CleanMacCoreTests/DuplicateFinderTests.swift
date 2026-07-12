import Foundation
import XCTest
@testable import CleanMacCore

final class DuplicateFinderTests: XCTestCase {
    func testHashConcurrencyIsAlwaysBounded() {
        XCTAssertEqual(DuplicateScanOptions(maxConcurrentHashes: 0).maxConcurrentHashes, 1)
        XCTAssertEqual(DuplicateScanOptions(maxConcurrentHashes: 2).maxConcurrentHashes, 2)
        XCTAssertEqual(DuplicateScanOptions(maxConcurrentHashes: 100).maxConcurrentHashes, 8)
    }

    func testProgressivePipelineUsesFullHashAfterMatchingPartialHash() async throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        try Data("ABCD1111".utf8).write(to: root.appending(path: "a.bin"))
        try Data("ABCD1111".utf8).write(to: root.appending(path: "b.bin"))
        try Data("ABCD2222".utf8).write(to: root.appending(path: "c.bin"))
        try Data("WXYZ3333".utf8).write(to: root.appending(path: "d.bin"))

        let report = try await DuplicateFinder().scan(
            root: root,
            options: DuplicateScanOptions(
                partialHashByteCount: 4,
                fullHashChunkByteCount: 3,
                maxConcurrentHashes: 2
            )
        )

        XCTAssertEqual(report.groups.count, 1)
        XCTAssertEqual(report.groups[0].original.name, "a.bin")
        XCTAssertEqual(report.groups[0].copies.map(\.name), ["b.bin"])
        XCTAssertEqual(report.reclaimableBytes, 8)
        XCTAssertFalse(report.groups[0].allFiles.contains { $0.name == "c.bin" })
        XCTAssertFalse(report.groups[0].allFiles.contains { $0.name == "d.bin" })
    }

    func testHardLinksDoNotCreateFalseDuplicateSavings() async throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let original = root.appending(path: "a.bin")
        let hardLink = root.appending(path: "b-hard-link.bin")
        let separateCopy = root.appending(path: "c-copy.bin")
        let data = Data("identical-content".utf8)
        try data.write(to: original)
        try FileManager.default.linkItem(at: original, to: hardLink)
        try data.write(to: separateCopy)

        let report = try await DuplicateFinder().scan(root: root)

        XCTAssertEqual(report.groups.count, 1)
        XCTAssertEqual(report.groups[0].allFiles.count, 2)
        XCTAssertEqual(report.groups[0].reclaimableBytes, Int64(data.count))
        XCTAssertFalse(report.groups[0].allFiles.contains { $0.name == "b-hard-link.bin" })
    }

    func testLargeCandidatesAreReportedThenIncludedInSlowMode() async throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let data = Data(repeating: 7, count: 256)
        try data.write(to: root.appending(path: "large-a.bin"))
        try data.write(to: root.appending(path: "large-b.bin"))

        let standardReport = try await DuplicateFinder().scan(
            root: root,
            options: DuplicateScanOptions(
                mode: .standard,
                partialHashByteCount: 16,
                largeFileThresholdBytes: 128,
                maxConcurrentHashes: 2
            )
        )
        XCTAssertTrue(standardReport.groups.isEmpty)
        XCTAssertEqual(Set(standardReport.deferredLargeCandidates.map(\.name)), ["large-a.bin", "large-b.bin"])

        let slowReport = try await DuplicateFinder().scan(
            root: root,
            options: DuplicateScanOptions(
                mode: .includeLargeFiles,
                partialHashByteCount: 16,
                largeFileThresholdBytes: 128,
                maxConcurrentHashes: 2
            )
        )
        XCTAssertEqual(slowReport.groups.count, 1)
        XCTAssertEqual(slowReport.groups[0].copies.count, 1)
        XCTAssertTrue(slowReport.deferredLargeCandidates.isEmpty)
    }

    func testOriginalChoicePrefersPlainShallowOlderPath() {
        let older = Date(timeIntervalSince1970: 1_000)
        let newer = Date(timeIntervalSince1970: 2_000)
        let plain = duplicateFile(path: "/Users/test/report.pdf", createdAt: older)
        let backup = duplicateFile(path: "/Users/test/Backups/report copy.pdf", createdAt: newer)
        let nested = duplicateFile(path: "/Users/test/Documents/Old/report.pdf", createdAt: older)

        XCTAssertEqual(DuplicateFinder.chooseOriginal(from: [backup, nested, plain]).id, plain.id)
    }

    func testScanCanBeCancelled() async throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        for index in 0..<200 {
            try Data(repeating: UInt8(index % 255), count: 128)
                .write(to: root.appending(path: "file-\(index).bin"))
        }

        let task = Task {
            try await DuplicateFinder().scan(root: root)
        }
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Cancelled duplicate scan unexpectedly completed")
        } catch is CancellationError {
            // Expected.
        }
    }

    func testCleanupPlannerProtectsOriginalAndRejectsUnknownChangedAndOutsidePaths() async throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let outsideRoot = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: outsideRoot) }

        let data = Data("same-content".utf8)
        let originalURL = root.appending(path: "a.bin")
        let copyURL = root.appending(path: "b.bin")
        try data.write(to: originalURL)
        try data.write(to: copyURL)

        let report = try await DuplicateFinder().scan(root: root)
        let group = try XCTUnwrap(report.groups.first)
        let originalID = group.original.id
        let copyID = try XCTUnwrap(group.copies.first?.id)

        let protectedPlan = DuplicateCleanupPlanner(root: root).plan(
            groups: [group],
            selectedCopyIDs: [originalID, copyID, "/unknown/path"]
        )
        XCTAssertEqual(protectedPlan.items.map(\.id), [copyID])
        XCTAssertEqual(Set(protectedPlan.rejectedItems.map(\.reason)), [.protectedOriginal, .unknownSelection])

        try Data("DIFF-content".utf8).write(to: copyURL)
        let changedPlan = DuplicateCleanupPlanner(root: root).plan(
            groups: [group],
            selectedCopyIDs: [copyID]
        )
        XCTAssertTrue(changedPlan.items.isEmpty)
        XCTAssertEqual(changedPlan.rejectedItems.first?.reason, .changedSinceScan)

        let outsideURL = outsideRoot.appending(path: "outside.bin")
        try data.write(to: outsideURL)
        let outsideFile = try makeDuplicateFile(at: outsideURL)
        let forgedGroup = DuplicateGroup(
            fullHash: group.fullHash,
            original: group.original,
            copies: [outsideFile]
        )
        let outsidePlan = DuplicateCleanupPlanner(root: root).plan(
            groups: [forgedGroup],
            selectedCopyIDs: [outsideFile.id]
        )
        XCTAssertTrue(outsidePlan.items.isEmpty)
        XCTAssertEqual(outsidePlan.rejectedItems.first?.reason, .outsideSelectedRoot)
    }

    func testCleanupExecutorMovesOnlyCopyAndLeavesOriginal() async throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let trash = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: trash) }

        let data = Data("keep-one-copy".utf8)
        let originalURL = root.appending(path: "a.bin")
        let copyURL = root.appending(path: "b.bin")
        try data.write(to: originalURL)
        try data.write(to: copyURL)

        let scanReport = try await DuplicateFinder().scan(root: root)
        let group = try XCTUnwrap(scanReport.groups.first)
        let copy = try XCTUnwrap(group.copies.first)
        let plan = DuplicateCleanupPlanner(root: root).plan(
            groups: [group],
            selectedCopyIDs: [copy.id]
        )
        let cleanupReport = DuplicateCleanupExecutor { url in
            let destination = trash.appending(path: url.lastPathComponent)
            try FileManager.default.moveItem(at: url, to: destination)
            return destination
        }.execute(plan: plan)

        XCTAssertEqual(cleanupReport.movedItems.map(\.id), [copy.id])
        XCTAssertTrue(FileManager.default.fileExists(atPath: group.original.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: copy.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: trash.appending(path: copy.name).path))
    }

    private func makeTemporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "CleanMacDuplicateTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func duplicateFile(path: String, createdAt: Date?) -> DuplicateFile {
        DuplicateFile(
            path: path,
            name: URL(fileURLWithPath: path).lastPathComponent,
            sizeBytes: 100,
            createdAt: createdAt,
            modifiedAt: nil,
            deviceID: 1,
            inode: UInt64(abs(path.hashValue))
        )
    }

    private func makeDuplicateFile(at url: URL) throws -> DuplicateFile {
        var fileInfo = stat()
        let result = url.path.withCString { lstat($0, &fileInfo) }
        XCTAssertEqual(result, 0)
        let values = try url.resourceValues(forKeys: [
            .fileSizeKey,
            .creationDateKey,
            .contentModificationDateKey
        ])
        return DuplicateFile(
            path: url.path,
            name: url.lastPathComponent,
            sizeBytes: Int64(try XCTUnwrap(values.fileSize)),
            createdAt: values.creationDate,
            modifiedAt: values.contentModificationDate,
            deviceID: UInt64(bitPattern: Int64(fileInfo.st_dev)),
            inode: UInt64(fileInfo.st_ino)
        )
    }
}
