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
        try setModificationDate(Date().addingTimeInterval(-8 * 24 * 60 * 60), for: logFile)
        try setModificationDate(Date().addingTimeInterval(-2 * 24 * 60 * 60), for: tempFile)

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

        XCTAssertEqual(report.items.first { $0.displayName == "TestApp" }?.reasons, [.applicationCache])
        XCTAssertEqual(report.items.first { $0.displayName == "cleanmac.log" }?.reasons, [.staleLog])
        XCTAssertEqual(report.items.first { $0.displayName == "scratch.tmp" }?.reasons, [.staleTemporary])

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

    func testScannerFindsExpandedDeveloperAndInstallerCategories() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let chromeRoot = home.appending(path: "Library/Caches/Google/Chrome", directoryHint: .isDirectory)
        let npmRoot = home.appending(path: ".npm", directoryHint: .isDirectory)
        let swiftPMRoot = home.appending(path: "Library/Caches/org.swift.swiftpm", directoryHint: .isDirectory)
        let downloads = home.appending(path: "Downloads", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: chromeRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: npmRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: swiftPMRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)

        let chromeCache = chromeRoot.appending(path: "Default", directoryHint: .isDirectory)
        let npmCache = npmRoot.appending(path: "_cacache", directoryHint: .isDirectory)
        let swiftCache = swiftPMRoot.appending(path: "repositories", directoryHint: .isDirectory)
        let installer = downloads.appending(path: "Tool.pkg")
        let document = downloads.appending(path: "Notes.txt")

        try FileManager.default.createDirectory(at: chromeCache, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: npmCache, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: swiftCache, withIntermediateDirectories: true)
        try writeBytes(count: 10, to: installer)
        try writeBytes(count: 10, to: document)

        let scanner = CleanupScanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let report = scanner.scan(
            categories: [.browserCaches, .nodePackageCaches, .swiftPackageBuilds, .downloadedInstallers],
            options: CleanupScanOptions(maxItemsPerCategory: 10, maxDescendantsPerItem: 50)
        )

        let itemsByCategory = Dictionary(grouping: report.items, by: \.category)
        XCTAssertEqual(itemsByCategory[.browserCaches]?.map(\.displayName), ["Chrome"])
        XCTAssertEqual(itemsByCategory[.nodePackageCaches]?.map(\.displayName), ["_cacache"])
        XCTAssertEqual(itemsByCategory[.swiftPackageBuilds]?.map(\.displayName), ["repositories"])
        XCTAssertEqual(itemsByCategory[.downloadedInstallers]?.map(\.displayName), ["Tool.pkg"])
        XCTAssertFalse(report.items.contains { $0.displayName == "Notes.txt" })

        XCTAssertEqual(itemsByCategory[.browserCaches]?.first?.reasons, [.browserCache])
        XCTAssertEqual(itemsByCategory[.nodePackageCaches]?.first?.reasons, [.nodePackageCache])
        XCTAssertEqual(itemsByCategory[.swiftPackageBuilds]?.first?.reasons, [.swiftPackageCache])
        XCTAssertEqual(itemsByCategory[.downloadedInstallers]?.first?.reasons, [.installerArchive])
    }

    func testDeveloperCacheRootsAreExactAndExcludeUserData() {
        let home = URL(fileURLWithPath: "/Users/Test")
        let resolver = CleanupRootResolver(
            homeDirectory: home,
            temporaryDirectory: URL(fileURLWithPath: "/tmp/Test")
        )
        let paths = [
            CleanupCategory.developerPackageCaches,
            .developerIDECaches,
            .developerAITemporaryFiles
        ].flatMap { resolver.rootURLs(for: $0).map(\.path) }

        let requiredSuffixes = [
            "/Library/Caches/Homebrew",
            "/Library/Caches/pip",
            "/.cargo/registry/cache",
            "/.cargo/registry/src",
            "/.gradle/caches",
            "/Application Support/Cursor/Cache",
            "/Application Support/Code/Cache",
            "/.codex/.tmp",
            "/.codex/tmp",
            "/.codex/cache",
            "/.claude/cache",
            "/.claude/paste-cache"
        ]
        for suffix in requiredSuffixes {
            XCTAssertTrue(paths.contains { $0.hasSuffix(suffix) }, "Missing exact root: \(suffix)")
        }

        let forbiddenFragments = [
            "/Cursor/User",
            "/Code/User",
            "/extensions",
            "/workspaceStorage",
            "/Backups",
            "/.codex/sessions",
            "/.codex/archived_sessions",
            "/.codex/shell_snapshots",
            "/.codex/memories",
            "/.claude/projects",
            "/.claude/history",
            "/.claude/shell-snapshots"
        ]
        for path in paths {
            for forbidden in forbiddenFragments {
                XCTAssertFalse(path.contains(forbidden), "Developer cleanup must not target \(forbidden): \(path)")
            }
        }
    }

    func testScannerFindsDeveloperCachesButNotNeighboringUserData() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let includedRoots = [
            "Library/Caches/Homebrew",
            "Library/Caches/pip",
            ".cargo/registry/cache",
            ".cargo/registry/src",
            ".gradle/caches",
            "Library/Application Support/Cursor/Cache",
            "Library/Application Support/Code/GPUCache",
            ".codex/.tmp",
            ".codex/tmp",
            ".codex/cache",
            ".claude/cache",
            ".claude/paste-cache"
        ]
        var expectedCandidatePaths: Set<String> = []
        for (index, relativeRoot) in includedRoots.enumerated() {
            let candidate = home.appending(path: relativeRoot, directoryHint: .isDirectory)
                .appending(path: "candidate-\(index)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: candidate, withIntermediateDirectories: true)
            try writeBytes(count: 16, to: candidate.appending(path: "cache.bin"))
            expectedCandidatePaths.insert(canonicalPath(candidate.path))
        }

        let forbiddenFiles = [
            ".codex/sessions/session.jsonl",
            ".codex/memories/MEMORY.md",
            ".claude/projects/project.json",
            "Library/Application Support/Cursor/User/settings.json",
            "Library/Application Support/Code/extensions/extension.bin"
        ].map { home.appending(path: $0) }
        for file in forbiddenFiles {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try writeBytes(count: 16, to: file)
        }

        let scanner = CleanupScanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let report = scanner.scan(
            categories: [.developerPackageCaches, .developerIDECaches, .developerAITemporaryFiles],
            options: CleanupScanOptions(maxItemsPerCategory: 40, maxDescendantsPerItem: 50)
        )
        let scannedPaths = Set(report.items.map { canonicalPath($0.path) })

        XCTAssertTrue(expectedCandidatePaths.isSubset(of: scannedPaths))
        XCTAssertTrue(report.items.allSatisfy { $0.risk == .safe })
        XCTAssertFalse(report.items.contains { item in
            forbiddenFiles.contains { canonicalPath($0.path) == canonicalPath(item.path) }
        })
    }

    func testXcodeDeveloperStorageUsesReviewAndAgeRules() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let deviceSupport = home.appending(path: "Library/Developer/Xcode/iOS DeviceSupport/17.0", directoryHint: .isDirectory)
        let previews = home.appending(path: "Library/Developer/Xcode/UserData/Previews/Simulator Devices", directoryHint: .isDirectory)
        let oldDevice = home.appending(path: "Library/Developer/CoreSimulator/Devices/OLD-DEVICE", directoryHint: .isDirectory)
        let recentDevice = home.appending(path: "Library/Developer/CoreSimulator/Devices/RECENT-DEVICE", directoryHint: .isDirectory)
        let oldRuntime = home.appending(path: "Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 16.simruntime", directoryHint: .isDirectory)
        let archive = home.appending(path: "Library/Developer/Xcode/Archives/2025-01-01/My App.xcarchive", directoryHint: .isDirectory)

        for directory in [deviceSupport, previews, oldDevice, recentDevice, oldRuntime, archive] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try writeBytes(count: 16, to: directory.appending(path: "data.bin"))
        }
        try setModificationDate(Date().addingTimeInterval(-200 * 24 * 60 * 60), for: oldDevice)
        try setModificationDate(Date().addingTimeInterval(-10 * 24 * 60 * 60), for: recentDevice)
        try setModificationDate(Date().addingTimeInterval(-220 * 24 * 60 * 60), for: oldRuntime)

        let scanner = CleanupScanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let report = scanner.scan(
            categories: [.xcodeDeviceSupport, .xcodePreviews, .xcodeSimulatorData, .xcodeArchives],
            options: CleanupScanOptions(
                maxItemsPerCategory: 20,
                maxDescendantsPerItem: 50,
                staleDeveloperDataAge: 180 * 24 * 60 * 60
            )
        )
        let itemsByPath = Dictionary(uniqueKeysWithValues: report.items.map { (canonicalPath($0.path), $0) })

        XCTAssertEqual(itemsByPath[canonicalPath(deviceSupport.path)]?.risk, .review)
        XCTAssertEqual(itemsByPath[canonicalPath(previews.path)]?.risk, .safe)
        XCTAssertEqual(itemsByPath[canonicalPath(oldDevice.path)]?.reasons, [.staleSimulatorData])
        XCTAssertEqual(itemsByPath[canonicalPath(oldRuntime.path)]?.reasons, [.staleSimulatorData])
        XCTAssertNil(itemsByPath[canonicalPath(recentDevice.path)])
        XCTAssertEqual(itemsByPath[canonicalPath(archive.path)]?.risk, .review)
        XCTAssertEqual(itemsByPath[canonicalPath(archive.path)]?.reasons, [.xcodeArchive])
        XCTAssertFalse(report.items.contains { $0.category == .xcodeArchives && $0.risk == .safe })
    }

    func testDeveloperPlannerRejectsSensitiveNeighborsAndBroadXcodePaths() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let aiCache = home.appending(path: ".codex/tmp/job", directoryHint: .isDirectory)
        let aiSession = home.appending(path: ".codex/sessions/session.jsonl")
        let archive = home.appending(path: "Library/Developer/Xcode/Archives/2025-01-01/App.xcarchive", directoryHint: .isDirectory)
        let archiveDay = archive.deletingLastPathComponent()
        let simulatorDevice = home.appending(path: "Library/Developer/CoreSimulator/Devices/DEVICE", directoryHint: .isDirectory)
        let simulatorNestedData = simulatorDevice.appending(path: "data/private", directoryHint: .isDirectory)

        for directory in [aiCache, archive, simulatorNestedData] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try FileManager.default.createDirectory(at: aiSession.deletingLastPathComponent(), withIntermediateDirectories: true)
        try writeBytes(count: 8, to: aiSession)

        let items = [
            makeScanItem(category: .developerAITemporaryFiles, path: aiCache.path, isDirectory: true),
            makeScanItem(category: .developerAITemporaryFiles, path: aiSession.path),
            makeScanItem(category: .xcodeArchives, path: archive.path, isDirectory: true),
            makeScanItem(category: .xcodeArchives, path: archiveDay.path, isDirectory: true),
            makeScanItem(category: .xcodeSimulatorData, path: simulatorDevice.path, isDirectory: true),
            makeScanItem(category: .xcodeSimulatorData, path: simulatorNestedData.path, isDirectory: true)
        ]
        let plan = CleanupPlanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
            .plan(for: items)

        XCTAssertEqual(Set(plan.items.map(\.originalPath)), Set([
            canonicalPath(aiCache.path),
            canonicalPath(archive.path),
            canonicalPath(simulatorDevice.path)
        ]))
        XCTAssertEqual(plan.rejectedItems.count, 3)
    }

    func testScannerReportsCategoryProgress() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let cacheFolder = home.appending(path: "Library/Caches/TestApp", directoryHint: .isDirectory)
        let downloads = home.appending(path: "Downloads", directoryHint: .isDirectory)
        let installer = downloads.appending(path: "Tool.pkg")

        try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)
        try writeBytes(count: 16, to: cacheFolder.appending(path: "cache.bin"))
        try writeBytes(count: 8, to: installer)

        let recorder = ProgressRecorder()
        let scanner = CleanupScanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let report = scanner.scan(
            categories: [.userCaches, .downloadedInstallers],
            options: CleanupScanOptions(maxItemsPerCategory: 10, maxDescendantsPerItem: 50),
            progress: recorder.append
        )
        let events = recorder.events

        XCTAssertEqual(events.first?.phase, .preparing)
        XCTAssertEqual(events.last?.phase, .completed)
        XCTAssertEqual(events.last?.fractionComplete, 1)
        XCTAssertEqual(events.last?.scannedItemCount, report.items.count)
        XCTAssertTrue(events.contains { $0.currentCategory == .userCaches && $0.phase == .measuring })
        XCTAssertTrue(events.contains { $0.currentCategory == .downloadedInstallers && $0.phase == .measuring })
    }

    func testDownloadsReviewUsesSmartRules() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let downloads = home.appending(path: "Downloads", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: downloads, withIntermediateDirectories: true)

        let recentSmall = downloads.appending(path: "Notes.txt")
        let staleFile = downloads.appending(path: "OldExport.mov")
        let largeFile = downloads.appending(path: "Video.mov")
        let installer = downloads.appending(path: "Tool.pkg")

        try writeBytes(count: 10, to: recentSmall)
        try writeBytes(count: 10, to: staleFile)
        try writeBytes(count: 8_192, to: largeFile)
        try writeBytes(count: 10, to: installer)
        try setModificationDate(Date().addingTimeInterval(-2 * 24 * 60 * 60), for: staleFile)

        let scanner = CleanupScanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let report = scanner.scan(
            categories: [.downloads],
            options: CleanupScanOptions(
                maxItemsPerCategory: 10,
                maxDescendantsPerItem: 50,
                largeDownloadThresholdBytes: 6_000,
                staleDownloadAge: 24 * 60 * 60
            )
        )

        let names = Set(report.items.map(\.displayName))
        XCTAssertEqual(names, ["OldExport.mov", "Tool.pkg", "Video.mov"])
        XCTAssertFalse(names.contains("Notes.txt"))
        XCTAssertTrue(report.items.allSatisfy { $0.risk == .review })

        let itemsByName = Dictionary(uniqueKeysWithValues: report.items.map { ($0.displayName, $0) })
        XCTAssertEqual(itemsByName["OldExport.mov"]?.reasons, [.oldDownload])
        XCTAssertEqual(itemsByName["Tool.pkg"]?.reasons, [.installerArchive])
        XCTAssertEqual(itemsByName["Video.mov"]?.reasons, [.largeDownload])
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

    func testCleanupPlannerAcceptsExpandedCategoryRoots() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let npmRoot = home.appending(path: ".npm", directoryHint: .isDirectory)
        let npmCache = npmRoot.appending(path: "_cacache", directoryHint: .isDirectory)
        let outsideFile = home.appending(path: "Library/Caches/Other/cache.bin")

        try FileManager.default.createDirectory(at: npmCache, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outsideFile.deletingLastPathComponent(), withIntermediateDirectories: true)
        try writeBytes(count: 10, to: outsideFile)

        let accepted = makeScanItem(category: .nodePackageCaches, path: npmCache.path, isDirectory: true)
        let outside = makeScanItem(category: .nodePackageCaches, path: outsideFile.path)
        let categoryRoot = makeScanItem(category: .nodePackageCaches, path: npmRoot.path, isDirectory: true)

        let planner = CleanupPlanner(homeDirectory: home, temporaryDirectory: root.appending(path: "Temp"))
        let plan = planner.plan(for: [accepted, outside, categoryRoot])

        XCTAssertEqual(plan.items.map(\.id), [accepted.id])
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

    func testCleanupRestorerMovesTrashItemBackToOriginalPath() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let originalParent = home.appending(path: "Library/Caches", directoryHint: .isDirectory)
        let trash = root.appending(path: "LocalTrash", directoryHint: .isDirectory)
        let trashedFolder = trash.appending(path: "TestApp", directoryHint: .isDirectory)
        let originalFolder = originalParent.appending(path: "TestApp", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: originalParent, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: trashedFolder, withIntermediateDirectories: true)
        try writeBytes(count: 16, to: trashedFolder.appending(path: "cache.bin"))

        let movedItem = makeMovedItem(
            category: .userCaches,
            originalPath: originalFolder.path,
            trashedPath: trashedFolder.path,
            isDirectory: true
        )

        let report = CleanupRestorer().restore(movedItems: [movedItem])

        XCTAssertEqual(report.restoredItems.map(\.restoredPath), [originalFolder.canonicalPath])
        XCTAssertEqual(report.failedItems.count, 0, report.failedItems.map(\.message).joined(separator: "\n"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalFolder.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: trashedFolder.path))
    }

    func testCleanupRestorerDoesNotOverwriteExistingOriginalPath() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let originalParent = home.appending(path: "Library/Caches", directoryHint: .isDirectory)
        let trash = root.appending(path: "LocalTrash", directoryHint: .isDirectory)
        let trashedFolder = trash.appending(path: "TestApp", directoryHint: .isDirectory)
        let originalFolder = originalParent.appending(path: "TestApp", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: trashedFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: originalFolder, withIntermediateDirectories: true)

        let movedItem = makeMovedItem(
            category: .userCaches,
            originalPath: originalFolder.path,
            trashedPath: trashedFolder.path,
            isDirectory: true
        )

        let report = CleanupRestorer().restore(movedItems: [movedItem])

        XCTAssertEqual(report.restoredItems.count, 0)
        XCTAssertEqual(report.failedItems.first?.reason, .destinationExists)
        XCTAssertTrue(FileManager.default.fileExists(atPath: originalFolder.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: trashedFolder.path))
    }

    func testApplicationScannerFindsOnlyThirdPartyAppsAndExactLeftovers() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let sharedApplications = root.appending(path: "Applications", directoryHint: .isDirectory)
        let userApplications = home.appending(path: "Applications", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: sharedApplications, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: userApplications, withIntermediateDirectories: true)

        let thirdPartyApp = try makeFakeApplication(
            named: "Example",
            bundleIdentifier: "com.example.editor",
            in: sharedApplications
        )
        _ = try makeFakeApplication(
            named: "AppleUtility",
            bundleIdentifier: "com.apple.utility",
            in: sharedApplications
        )
        _ = try makeFakeApplication(
            named: "CleanMac",
            bundleIdentifier: "com.codex.cleanmac",
            in: userApplications
        )

        let cache = home.appending(path: "Library/Caches/com.example.editor", directoryHint: .isDirectory)
        let preferences = home.appending(path: "Library/Preferences/com.example.editor.plist")
        let savedState = home.appending(path: "Library/Saved Application State/com.example.editor.savedState", directoryHint: .isDirectory)
        let logs = home.appending(path: "Library/Logs/com.example.editor", directoryHint: .isDirectory)
        let applicationSupport = home.appending(path: "Library/Application Support/com.example.editor", directoryHint: .isDirectory)

        for folder in [cache, savedState, logs, applicationSupport] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try writeBytes(count: 8, to: folder.appending(path: "data.bin"))
        }
        try FileManager.default.createDirectory(at: preferences.deletingLastPathComponent(), withIntermediateDirectories: true)
        try writeBytes(count: 8, to: preferences)

        let alias = sharedApplications.appending(path: "Example Alias.app")
        try FileManager.default.createSymbolicLink(at: alias, withDestinationURL: thirdPartyApp)

        let report = InstalledApplicationScanner(
            applicationDirectories: [sharedApplications, userApplications],
            homeDirectory: home,
            excludedBundleIdentifiers: ["com.codex.cleanmac"],
            maxDescendantsPerItem: 100
        ).scan()

        XCTAssertEqual(report.applications.map(\.name), ["Example"])
        XCTAssertEqual(report.applications.first?.bundleIdentifier, "com.example.editor")
        XCTAssertEqual(
            Set(report.applications.first?.leftovers.map(\.kind) ?? []),
            Set(ApplicationLeftoverKind.allCases)
        )
        XCTAssertFalse(report.applications.first?.leftovers.contains { $0.path == applicationSupport.path } ?? true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: thirdPartyApp.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: applicationSupport.path))
    }

    func testApplicationRemovalMovesAppFirstThenExactLeftovers() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let applications = root.appending(path: "Applications", directoryHint: .isDirectory)
        let trash = root.appending(path: "Trash", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: applications, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)

        let appURL = try makeFakeApplication(
            named: "Example",
            bundleIdentifier: "com.example.editor",
            in: applications
        )
        let cache = home.appending(path: "Library/Caches/com.example.editor", directoryHint: .isDirectory)
        let preferences = home.appending(path: "Library/Preferences/com.example.editor.plist")
        let applicationSupport = home.appending(path: "Library/Application Support/com.example.editor", directoryHint: .isDirectory)
        for folder in [cache, applicationSupport] {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try writeBytes(count: 8, to: folder.appending(path: "data.bin"))
        }
        try FileManager.default.createDirectory(at: preferences.deletingLastPathComponent(), withIntermediateDirectories: true)
        try writeBytes(count: 8, to: preferences)

        let application = try XCTUnwrap(InstalledApplicationScanner(
            applicationDirectories: [applications],
            homeDirectory: home,
            maxDescendantsPerItem: 100
        ).scan().applications.first)
        let plan = ApplicationRemovalPlanner(
            applicationDirectories: [applications],
            homeDirectory: home
        ).plan(
            for: application,
            selectedLeftoverIDs: Set(application.leftovers.map(\.id))
        )

        var movedPaths: [String] = []
        let report = ApplicationRemovalExecutor { url in
            movedPaths.append(url.path)
            let destination = trash.appending(path: "\(movedPaths.count)-\(url.lastPathComponent)")
            try FileManager.default.moveItem(at: url, to: destination)
            return destination
        }.execute(plan: plan)

        XCTAssertTrue(report.applicationMoved)
        XCTAssertEqual(report.failedItems.count, 0)
        XCTAssertEqual(report.rejectedItems.count, 0)
        XCTAssertEqual(movedPaths.first, appURL.path)
        XCTAssertEqual(Set(movedPaths.dropFirst()), Set([cache.path, preferences.path]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: appURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: cache.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: preferences.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: applicationSupport.path))
    }

    func testApplicationRemovalDoesNotTouchLeftoversWhenAppMoveFails() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let applications = root.appending(path: "Applications", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: applications, withIntermediateDirectories: true)
        let appURL = try makeFakeApplication(
            named: "Example",
            bundleIdentifier: "com.example.editor",
            in: applications
        )
        let cache = home.appending(path: "Library/Caches/com.example.editor", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
        try writeBytes(count: 8, to: cache.appending(path: "data.bin"))

        let application = try XCTUnwrap(InstalledApplicationScanner(
            applicationDirectories: [applications],
            homeDirectory: home,
            maxDescendantsPerItem: 100
        ).scan().applications.first)
        let plan = ApplicationRemovalPlanner(
            applicationDirectories: [applications],
            homeDirectory: home
        ).plan(for: application, selectedLeftoverIDs: Set(application.leftovers.map(\.id)))

        var attemptedPaths: [String] = []
        let report = ApplicationRemovalExecutor { url in
            attemptedPaths.append(url.path)
            throw NSError(domain: "CleanMacCoreTests", code: 1)
        }.execute(plan: plan)

        XCTAssertFalse(report.applicationMoved)
        XCTAssertEqual(report.failedItems.count, 1)
        XCTAssertEqual(attemptedPaths, [appURL.path])
        XCTAssertTrue(FileManager.default.fileExists(atPath: appURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: cache.path))
    }

    func testApplicationRemovalPlannerRejectsOutsideAppAndUnknownLeftover() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let allowedApplications = root.appending(path: "Applications", directoryHint: .isDirectory)
        let outsideApplications = root.appending(path: "Other", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: allowedApplications, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outsideApplications, withIntermediateDirectories: true)
        _ = try makeFakeApplication(
            named: "Outside",
            bundleIdentifier: "com.example.outside",
            in: outsideApplications
        )

        let outsideApplication = try XCTUnwrap(InstalledApplicationScanner(
            applicationDirectories: [outsideApplications],
            homeDirectory: home
        ).scan().applications.first)
        let outsidePlan = ApplicationRemovalPlanner(
            applicationDirectories: [allowedApplications],
            homeDirectory: home
        ).plan(for: outsideApplication, selectedLeftoverIDs: [])

        XCTAssertNil(outsidePlan.applicationItem)
        XCTAssertEqual(outsidePlan.rejectedItems.first?.reason, .invalidApplicationPath)

        _ = try makeFakeApplication(
            named: "Allowed",
            bundleIdentifier: "com.example.allowed",
            in: allowedApplications
        )
        let allowedApplication = try XCTUnwrap(InstalledApplicationScanner(
            applicationDirectories: [allowedApplications],
            homeDirectory: home
        ).scan().applications.first)
        let forgedPath = home.appending(path: "Library/Application Support/com.example.allowed").path
        let forgedPlan = ApplicationRemovalPlanner(
            applicationDirectories: [allowedApplications],
            homeDirectory: home
        ).plan(for: allowedApplication, selectedLeftoverIDs: [forgedPath])

        XCTAssertNotNil(forgedPlan.applicationItem)
        XCTAssertTrue(forgedPlan.leftoverItems.isEmpty)
        XCTAssertEqual(forgedPlan.rejectedItems.first?.reason, .invalidLeftover)
    }

    func testCleanupHistoryStoreRoundTripsStatusesAndUsesPrivatePermissions() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let fileURL = root.appending(path: "Support/CleanMac/cleanup-history.json")
        let store = CleanupHistoryStore(fileURL: fileURL)
        let movedAt = Date(timeIntervalSinceReferenceDate: 123_456)
        var restoredRecord = CleanupHistoryRecord(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            category: .userCaches,
            originalPath: "/Users/test/Library/Caches/Example",
            trashedPath: "/Users/test/.Trash/Example",
            movedAt: movedAt,
            sizeBytes: 42
        )
        restoredRecord.markRestored(at: movedAt.addingTimeInterval(60))

        var failedRecord = CleanupHistoryRecord(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            category: .downloads,
            originalPath: "/Users/test/Downloads/Archive.zip",
            trashedPath: "/Users/test/.Trash/Archive.zip",
            movedAt: movedAt.addingTimeInterval(-60),
            sizeBytes: 84
        )
        failedRecord.markRestoreFailed(reason: .destinationExists)

        try store.save([restoredRecord, failedRecord])

        XCTAssertEqual(store.load(), [restoredRecord, failedRecord])
        let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        XCTAssertEqual(fileAttributes[.posixPermissions] as? NSNumber, NSNumber(value: 0o600))
        let directoryAttributes = try FileManager.default.attributesOfItem(
            atPath: fileURL.deletingLastPathComponent().path
        )
        XCTAssertEqual(directoryAttributes[.posixPermissions] as? NSNumber, NSNumber(value: 0o700))
    }

    func testCleanupHistoryStoreCapsAndDeduplicatesRecordsWithUniqueOperationIDs() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let originalPath = "/Users/test/Library/Caches/Repeated"
        let movedItem = makeMovedItem(
            category: .userCaches,
            originalPath: originalPath,
            trashedPath: "/Users/test/.Trash/Repeated"
        )
        let first = CleanupHistoryRecord(movedItem: movedItem, movedAt: Date())
        let second = CleanupHistoryRecord(movedItem: movedItem, movedAt: Date())
        let third = CleanupHistoryRecord(
            category: .userCaches,
            originalPath: "/Users/test/Library/Caches/Third",
            trashedPath: "/Users/test/.Trash/Third",
            movedAt: Date(),
            sizeBytes: 1
        )
        XCTAssertNotEqual(first.id, second.id)

        let store = CleanupHistoryStore(
            fileURL: root.appending(path: "cleanup-history.json"),
            maximumRecordCount: 2
        )
        try store.save([first, first, second, third])

        XCTAssertEqual(store.load().map(\.id), [first.id, second.id])
    }

    func testCleanupHistoryStoreUpsertMergesWindowSnapshotsWithoutDowngradingRestoredState() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let store = CleanupHistoryStore(fileURL: root.appending(path: "cleanup-history.json"))
        let first = CleanupHistoryRecord(
            category: .userCaches,
            originalPath: "/Users/test/Library/Caches/First",
            trashedPath: "/Users/test/.Trash/First",
            movedAt: Date(),
            sizeBytes: 1
        )
        let second = CleanupHistoryRecord(
            category: .downloads,
            originalPath: "/Users/test/Downloads/Second.zip",
            trashedPath: "/Users/test/.Trash/Second.zip",
            movedAt: Date(),
            sizeBytes: 2
        )

        XCTAssertEqual(try store.upserting([first]).map(\.id), [first.id])
        XCTAssertEqual(try store.upserting([second]).map(\.id), [second.id, first.id])

        var restoredFirst = first
        restoredFirst.markRestored(at: Date())
        let merged = try store.upserting([restoredFirst])
        XCTAssertEqual(merged.map(\.id), [second.id, first.id])
        XCTAssertEqual(merged.last?.status, .restored)

        var staleFailedFirst = first
        staleFailedFirst.markRestoreFailed(reason: .missingTrashItem)
        let protectedState = try store.upserting([staleFailedFirst])
        XCTAssertEqual(protectedState.last?.status, .restored)
    }

    func testCleanupHistoryStoreFailsClosedForCorruptUnknownOrOversizedFiles() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let fileURL = root.appending(path: "cleanup-history.json")
        let store = CleanupHistoryStore(fileURL: fileURL)

        try Data("{not-json".utf8).write(to: fileURL)
        XCTAssertTrue(store.load().isEmpty)

        try Data("{\"schemaVersion\":999,\"records\":[]}".utf8).write(to: fileURL)
        XCTAssertTrue(store.load().isEmpty)

        try Data(repeating: 1, count: 1_048_577).write(to: fileURL)
        XCTAssertTrue(store.load().isEmpty)
    }

    func testPersistedCleanupHistoryRestoresOnlyValidatedCanonicalPaths() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let temp = root.appending(path: "Temp", directoryHint: .isDirectory)
        let cacheRoot = home.appending(path: "Library/Caches", directoryHint: .isDirectory)
        let trash = home.appending(path: ".Trash", directoryHint: .isDirectory)
        let original = cacheRoot.appending(path: "Example", directoryHint: .isDirectory)
        let trashed = trash.appending(path: "Example", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: trashed, withIntermediateDirectories: true)
        try writeBytes(count: 16, to: trashed.appending(path: "cache.bin"))

        let record = CleanupHistoryRecord(
            category: .userCaches,
            originalPath: original.path,
            trashedPath: trashed.path,
            movedAt: Date(),
            sizeBytes: 16
        )
        let store = CleanupHistoryStore(fileURL: root.appending(path: "cleanup-history.json"))
        try store.save([record])

        let report = CleanupRestorer(
            homeDirectory: home,
            temporaryDirectory: temp,
            trashDirectory: trash
        ).restore(historyRecords: store.load())

        XCTAssertEqual(report.restoredItems.map(\.restoredPath), [original.canonicalPath])
        XCTAssertTrue(report.failedItems.isEmpty, report.failedItems.map(\.message).joined(separator: "\n"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: trashed.path))

        let repeatedReport = CleanupRestorer(
            homeDirectory: home,
            temporaryDirectory: temp,
            trashDirectory: trash
        ).restore(historyRecords: store.load())
        XCTAssertEqual(repeatedReport.failedItems.first?.reason, .missingTrashItem)
        XCTAssertTrue(FileManager.default.fileExists(atPath: original.path))
    }

    func testPersistedCleanupHistoryRejectsSourcesOutsideDirectTrashChildren() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let temp = root.appending(path: "Temp", directoryHint: .isDirectory)
        let cacheRoot = home.appending(path: "Library/Caches", directoryHint: .isDirectory)
        let trash = home.appending(path: ".Trash", directoryHint: .isDirectory)
        let nestedTrash = trash.appending(path: "Folder", directoryHint: .isDirectory)
        let outside = root.appending(path: "Outside", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: nestedTrash, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)

        let outsideItem = outside.appending(path: "outside.bin")
        let nestedItem = nestedTrash.appending(path: "nested.bin")
        let directItem = trash.appending(path: "direct.bin")
        try writeBytes(count: 1, to: outsideItem)
        try writeBytes(count: 1, to: nestedItem)
        try writeBytes(count: 1, to: directItem)
        let symbolicLink = trash.appending(path: "alias.bin")
        try FileManager.default.createSymbolicLink(at: symbolicLink, withDestinationURL: outsideItem)
        let parentAlias = trash.appending(path: "ParentAlias", directoryHint: .isDirectory)
        try FileManager.default.createSymbolicLink(at: parentAlias, withDestinationURL: trash)
        let aliasedParentItem = parentAlias.appending(path: directItem.lastPathComponent)

        let destination = cacheRoot.appending(path: "Restored.bin").path
        let records = [outsideItem, nestedItem, symbolicLink, aliasedParentItem].map {
            CleanupHistoryRecord(
                category: .userCaches,
                originalPath: destination,
                trashedPath: $0.path,
                movedAt: Date(),
                sizeBytes: 1
            )
        }
        var moveCount = 0
        let report = CleanupRestorer(
            homeDirectory: home,
            temporaryDirectory: temp,
            trashDirectory: trash,
            moveHandler: { _, _ in moveCount += 1 }
        ).restore(historyRecords: records)

        XCTAssertEqual(moveCount, 0)
        XCTAssertEqual(
            report.failedItems.map(\.reason),
            [.outsideTrash, .outsideTrash, .symbolicLink, .outsideTrash]
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: outsideItem.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: nestedItem.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directItem.path))
    }

    func testPersistedCleanupHistoryRejectsForgedDestinationsBeforeMove() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let home = root.appending(path: "Home", directoryHint: .isDirectory)
        let temp = root.appending(path: "Temp", directoryHint: .isDirectory)
        let cacheRoot = home.appending(path: "Library/Caches", directoryHint: .isDirectory)
        let trash = home.appending(path: ".Trash", directoryHint: .isDirectory)
        let outside = root.appending(path: "Outside", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let trashedItem = trash.appending(path: "Stored.bin")
        try writeBytes(count: 1, to: trashedItem)

        let linkedParent = cacheRoot.appending(path: "Linked", directoryHint: .isDirectory)
        try FileManager.default.createSymbolicLink(at: linkedParent, withDestinationURL: outside)
        let forgedPaths = [
            outside.appending(path: "Outside.bin").path,
            home.appending(path: "Library/Caches-Evil/Prefix.bin").path,
            cacheRoot.path,
            linkedParent.appending(path: "Escaped.bin").path,
            cacheRoot.appending(path: "WrongCategory.bin").path
        ]
        let records = forgedPaths.enumerated().map { index, path in
            CleanupHistoryRecord(
                category: index == forgedPaths.count - 1 ? .downloads : .userCaches,
                originalPath: path,
                trashedPath: trashedItem.path,
                movedAt: Date(),
                sizeBytes: 1
            )
        }
        var moveCount = 0
        let report = CleanupRestorer(
            homeDirectory: home,
            temporaryDirectory: temp,
            trashDirectory: trash,
            moveHandler: { _, _ in moveCount += 1 }
        ).restore(historyRecords: records)

        XCTAssertEqual(moveCount, 0)
        XCTAssertEqual(
            report.failedItems.map(\.reason),
            [
                .outsideAllowedRoot,
                .missingOriginalParent,
                .outsideAllowedRoot,
                .outsideAllowedRoot,
                .outsideAllowedRoot
            ]
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: trashedItem.path))
    }

    func testSecureRestoreMoveRejectsSymlinkInIntermediateParentComponent() throws {
        let root = try makeTemporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }

        let trash = root.appending(path: "Trash", directoryHint: .isDirectory)
        let allowed = root.appending(path: "Allowed", directoryHint: .isDirectory)
        let destinationParent = allowed.appending(path: "Nested", directoryHint: .isDirectory)
        let outside = root.appending(path: "Outside", directoryHint: .isDirectory)
        let outsideParent = outside.appending(path: "Nested", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: trash, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: destinationParent, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outsideParent, withIntermediateDirectories: true)

        let source = trash.appending(path: "Stored.bin")
        let destination = destinationParent.appending(path: "Stored.bin")
        try writeBytes(count: 1, to: source)
        let canonicalSource = URL(fileURLWithPath: source.canonicalPath)
        let canonicalDestination = URL(fileURLWithPath: destinationParent.canonicalPath)
            .appending(path: destination.lastPathComponent)

        let originalAllowed = root.appending(path: "OriginalAllowed", directoryHint: .isDirectory)
        try FileManager.default.moveItem(at: allowed, to: originalAllowed)
        try FileManager.default.createSymbolicLink(at: allowed, withDestinationURL: outside)

        XCTAssertThrowsError(
            try CleanupRestorer.secureMove(
                source: canonicalSource,
                destination: canonicalDestination
            )
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: source.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: outsideParent.appending(path: "Stored.bin").path))
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

    private func makeFakeApplication(
        named name: String,
        bundleIdentifier: String,
        in directory: URL
    ) throws -> URL {
        let applicationURL = directory.appending(path: "\(name).app", directoryHint: .isDirectory)
        let contentsURL = applicationURL.appending(path: "Contents", directoryHint: .isDirectory)
        let executableURL = contentsURL.appending(path: "MacOS/\(name)")
        try FileManager.default.createDirectory(
            at: executableURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let info: [String: Any] = [
            "CFBundleIdentifier": bundleIdentifier,
            "CFBundleDisplayName": name,
            "CFBundleName": name
        ]
        let infoData = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try infoData.write(to: contentsURL.appending(path: "Info.plist"))
        try writeBytes(count: 16, to: executableURL)
        return applicationURL
    }

    private func setModificationDate(_ date: Date, for url: URL) throws {
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }

    private func canonicalPath(_ path: String) -> String {
        URL(fileURLWithPath: path).canonicalPath
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
            risk: reviewCategories.contains(category) ? .review : .safe
        )
    }

    private func makeMovedItem(
        category: CleanupCategory,
        originalPath: String,
        trashedPath: String,
        isDirectory: Bool = false
    ) -> CleanupMovedItem {
        let scanItem = makeScanItem(
            category: category,
            path: originalPath,
            sizeBytes: 1,
            isDirectory: isDirectory
        )
        return CleanupMovedItem(
            item: CleanupPlanItem(scanItem: scanItem, originalPath: originalPath),
            trashedPath: trashedPath
        )
    }

    private var reviewCategories: Set<CleanupCategory> {
        [
            .downloads,
            .downloadedInstallers,
            .trash,
            .xcodeDerivedData,
            .xcodeDeviceSupport,
            .xcodeSimulatorData,
            .xcodeArchives
        ]
    }
}

private final class ProgressRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [CleanupScanProgress] = []

    func append(_ progress: CleanupScanProgress) {
        lock.lock()
        storage.append(progress)
        lock.unlock()
    }

    var events: [CleanupScanProgress] {
        lock.lock()
        let copy = storage
        lock.unlock()
        return copy
    }
}
