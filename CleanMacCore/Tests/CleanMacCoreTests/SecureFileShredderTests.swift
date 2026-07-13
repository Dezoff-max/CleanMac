import Darwin
import Foundation
import XCTest
@testable import CleanMacCore

final class SecureFileShredderTests: XCTestCase {
    func testShredOverwritesBeforeDirectRemoval() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appending(path: "secret.bin")
        let original = Data(repeating: 0x41, count: 2 * 1024 * 1024)
        try original.write(to: file)

        let candidate = try SecureFileShredder().inspect(url: file)
        let probe = ShredOverwriteProbe(original: original)
        let shredder = SecureFileShredder(beforeUnlink: probe.inspect)

        let removedBytes = try shredder.shred(candidate)

        XCTAssertEqual(removedBytes, Int64(original.count))
        XCTAssertTrue(probe.didInspect)
        XCTAssertTrue(probe.wasFullyOverwritten)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testInspectionRejectsDirectoriesSymlinksHardLinksAndPackages() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        XCTAssertThrowsError(try SecureFileShredder().inspect(url: root)) { error in
            XCTAssertEqual(error as? SecureDeletionError, .notRegularFile)
        }

        let regularFile = root.appending(path: "regular.txt")
        try Data("value".utf8).write(to: regularFile)

        let symlink = root.appending(path: "link.txt")
        try FileManager.default.createSymbolicLink(at: symlink, withDestinationURL: regularFile)
        XCTAssertThrowsError(try SecureFileShredder().inspect(url: symlink)) { error in
            XCTAssertEqual(error as? SecureDeletionError, .symbolicLink)
        }

        let hardLink = root.appending(path: "hard-link.txt")
        try FileManager.default.linkItem(at: regularFile, to: hardLink)
        XCTAssertThrowsError(try SecureFileShredder().inspect(url: regularFile)) { error in
            XCTAssertEqual(error as? SecureDeletionError, .multipleHardLinks)
        }

        let appContents = root
            .appending(path: "Unsafe.app", directoryHint: .isDirectory)
            .appending(path: "Contents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: appContents, withIntermediateDirectories: true)
        let packagedFile = appContents.appending(path: "payload.bin")
        try Data("payload".utf8).write(to: packagedFile)
        XCTAssertThrowsError(try SecureFileShredder().inspect(url: packagedFile)) { error in
            XCTAssertEqual(error as? SecureDeletionError, .packageContent)
        }
    }

    func testShredRejectsAFileChangedAfterReview() throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appending(path: "changing.bin")
        try Data(repeating: 0x22, count: 128).write(to: file)
        let candidate = try SecureFileShredder().inspect(url: file)

        let handle = try FileHandle(forWritingTo: file)
        try handle.seekToEnd()
        try handle.write(contentsOf: Data([0x33]))
        try handle.close()

        XCTAssertThrowsError(try SecureFileShredder().shred(candidate)) { error in
            XCTAssertEqual(error as? SecureDeletionError, .fileChanged)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertEqual(try Data(contentsOf: file).count, 129)
    }

    func testInspectionRejectsCanonicalSystemAlias() throws {
        let hosts = URL(fileURLWithPath: "/etc/hosts")
        XCTAssertThrowsError(try SecureFileShredder().inspect(url: hosts)) { error in
            XCTAssertEqual(error as? SecureDeletionError, .protectedPath)
        }
    }

    private func makeRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "CleanMac-ShredderTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }
}

private final class ShredOverwriteProbe: @unchecked Sendable {
    private let lock = NSLock()
    private let original: Data
    private var inspected = false
    private var fullyOverwritten = false

    init(original: Data) {
        self.original = original
    }

    var didInspect: Bool {
        lock.withLock { inspected }
    }

    var wasFullyOverwritten: Bool {
        lock.withLock { fullyOverwritten }
    }

    func inspect(path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        lock.withLock {
            inspected = true
            fullyOverwritten = data.count == original.count && data != original
        }
    }
}
