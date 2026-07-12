import CryptoKit
import Darwin
import Foundation

public enum DuplicateScanMode: String, Sendable {
    case standard
    case includeLargeFiles
}

public struct DuplicateScanOptions: Equatable, Sendable {
    public var mode: DuplicateScanMode
    public var partialHashByteCount: Int
    public var fullHashChunkByteCount: Int
    public var largeFileThresholdBytes: Int64
    public var maxConcurrentHashes: Int
    public var maxFiles: Int

    public init(
        mode: DuplicateScanMode = .standard,
        partialHashByteCount: Int = 128 * 1024,
        fullHashChunkByteCount: Int = 1024 * 1024,
        largeFileThresholdBytes: Int64 = 500 * 1024 * 1024,
        maxConcurrentHashes: Int = 2,
        maxFiles: Int = 250_000
    ) {
        self.mode = mode
        self.partialHashByteCount = max(1, partialHashByteCount)
        self.fullHashChunkByteCount = max(1, fullHashChunkByteCount)
        self.largeFileThresholdBytes = max(1, largeFileThresholdBytes)
        self.maxConcurrentHashes = min(max(1, maxConcurrentHashes), 8)
        self.maxFiles = max(1, maxFiles)
    }
}

public enum DuplicateScanPhase: String, Sendable {
    case enumerating
    case groupingBySize
    case partialHashing
    case fullHashing
    case finalizing
    case completed
}

public struct DuplicateScanProgress: Equatable, Sendable {
    public let phase: DuplicateScanPhase
    public let currentPath: String?
    public let discoveredFileCount: Int
    public let candidateFileCount: Int
    public let hashedFileCount: Int

    public init(
        phase: DuplicateScanPhase,
        currentPath: String?,
        discoveredFileCount: Int,
        candidateFileCount: Int,
        hashedFileCount: Int
    ) {
        self.phase = phase
        self.currentPath = currentPath
        self.discoveredFileCount = max(0, discoveredFileCount)
        self.candidateFileCount = max(0, candidateFileCount)
        self.hashedFileCount = max(0, hashedFileCount)
    }
}

public struct DuplicateFile: Identifiable, Hashable, Sendable {
    public let id: String
    public let path: String
    public let name: String
    public let sizeBytes: Int64
    public let createdAt: Date?
    public let modifiedAt: Date?
    public let deviceID: UInt64
    public let inode: UInt64

    public init(
        path: String,
        name: String,
        sizeBytes: Int64,
        createdAt: Date?,
        modifiedAt: Date?,
        deviceID: UInt64,
        inode: UInt64
    ) {
        self.id = path
        self.path = path
        self.name = name
        self.sizeBytes = sizeBytes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deviceID = deviceID
        self.inode = inode
    }
}

public struct DuplicateGroup: Identifiable, Hashable, Sendable {
    public let id: String
    public let fullHash: String
    public let original: DuplicateFile
    public let copies: [DuplicateFile]

    public init(fullHash: String, original: DuplicateFile, copies: [DuplicateFile]) {
        self.id = "\(original.sizeBytes):\(fullHash)"
        self.fullHash = fullHash
        self.original = original
        self.copies = copies
    }

    public var allFiles: [DuplicateFile] {
        [original] + copies
    }

    public var reclaimableBytes: Int64 {
        let result = original.sizeBytes.multipliedReportingOverflow(by: Int64(copies.count))
        return result.overflow ? Int64.max : result.partialValue
    }
}

public struct DuplicateScanIssue: Equatable, Sendable {
    public let path: String
    public let message: String

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}

public struct DuplicateScanReport: Equatable, Sendable {
    public let rootPath: String
    public let scannedAt: Date
    public let durationSeconds: TimeInterval
    public let discoveredFileCount: Int
    public let groups: [DuplicateGroup]
    public let deferredLargeCandidates: [DuplicateFile]
    public let issues: [DuplicateScanIssue]

    public init(
        rootPath: String,
        scannedAt: Date,
        durationSeconds: TimeInterval,
        discoveredFileCount: Int,
        groups: [DuplicateGroup],
        deferredLargeCandidates: [DuplicateFile],
        issues: [DuplicateScanIssue]
    ) {
        self.rootPath = rootPath
        self.scannedAt = scannedAt
        self.durationSeconds = durationSeconds
        self.discoveredFileCount = discoveredFileCount
        self.groups = groups
        self.deferredLargeCandidates = deferredLargeCandidates
        self.issues = issues
    }

    public var copyCount: Int {
        groups.reduce(0) { $0 + $1.copies.count }
    }

    public var reclaimableBytes: Int64 {
        groups.reduce(0) { total, group in
            let result = total.addingReportingOverflow(group.reclaimableBytes)
            return result.overflow ? Int64.max : result.partialValue
        }
    }
}

public enum DuplicateFinderError: Error, Equatable, Sendable {
    case rootIsUnavailable
    case rootIsNotDirectory
}

public struct DuplicateFinder {
    private let fileManager: FileManager
    private let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isRegularFileKey,
        .isSymbolicLinkKey,
        .fileSizeKey,
        .creationDateKey,
        .contentModificationDateKey
    ]

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func scan(
        root: URL,
        options: DuplicateScanOptions = DuplicateScanOptions(),
        progress: (@Sendable (DuplicateScanProgress) -> Void)? = nil
    ) async throws -> DuplicateScanReport {
        let startedAt = Date()
        let rootURL = root.resolvingSymlinksInPath().standardizedFileURL
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: rootURL.path, isDirectory: &isDirectory) else {
            throw DuplicateFinderError.rootIsUnavailable
        }
        guard isDirectory.boolValue else {
            throw DuplicateFinderError.rootIsNotDirectory
        }

        var issues: [DuplicateScanIssue] = []
        let files = try enumerateFiles(
            rootURL: rootURL,
            maxFiles: options.maxFiles,
            issues: &issues,
            progress: progress
        )

        try Task.checkCancellation()
        progress?(DuplicateScanProgress(
            phase: .groupingBySize,
            currentPath: nil,
            discoveredFileCount: files.count,
            candidateFileCount: 0,
            hashedFileCount: 0
        ))

        let sizeGroups = Dictionary(grouping: files, by: \.sizeBytes)
            .values
            .filter { $0.count > 1 }
            .map(Self.removingHardLinks)
            .filter { $0.count > 1 }
            .sorted { ($0.first?.sizeBytes ?? 0) > ($1.first?.sizeBytes ?? 0) }

        let largeGroups = sizeGroups.filter { ($0.first?.sizeBytes ?? 0) > options.largeFileThresholdBytes }
        let deferredLargeCandidates = options.mode == .standard
            ? largeGroups.flatMap { $0 }.sorted(by: Self.largerFileFirst)
            : []
        let activeGroups = options.mode == .standard
            ? sizeGroups.filter { ($0.first?.sizeBytes ?? 0) <= options.largeFileThresholdBytes }
            : sizeGroups
        let partialCandidates = activeGroups.flatMap { $0 }

        let partialOutcomes = try await hashFiles(
            partialCandidates,
            stage: .partial,
            options: options,
            phase: .partialHashing,
            discoveredFileCount: files.count,
            progress: progress
        )
        issues.append(contentsOf: partialOutcomes.compactMap(\.issue))

        let partialGroups = Dictionary(
            grouping: partialOutcomes.compactMap(\.success),
            by: { "\($0.file.sizeBytes):\($0.hash)" }
        )
        .values
        .filter { $0.count > 1 }
        let fullCandidates = partialGroups.flatMap { $0.map(\.file) }

        let fullOutcomes = try await hashFiles(
            fullCandidates,
            stage: .full,
            options: options,
            phase: .fullHashing,
            discoveredFileCount: files.count,
            progress: progress
        )
        issues.append(contentsOf: fullOutcomes.compactMap(\.issue))

        try Task.checkCancellation()
        progress?(DuplicateScanProgress(
            phase: .finalizing,
            currentPath: nil,
            discoveredFileCount: files.count,
            candidateFileCount: fullCandidates.count,
            hashedFileCount: fullOutcomes.count
        ))

        let fullGroups = Dictionary(
            grouping: fullOutcomes.compactMap(\.success),
            by: { "\($0.file.sizeBytes):\($0.hash)" }
        )
        let groups = fullGroups.values.compactMap { matches -> DuplicateGroup? in
            let uniqueFiles = Self.removingHardLinks(matches.map(\.file))
            guard uniqueFiles.count > 1, let hash = matches.first?.hash else {
                return nil
            }
            let original = Self.chooseOriginal(from: uniqueFiles)
            let copies = uniqueFiles
                .filter { $0.id != original.id }
                .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            guard !copies.isEmpty else {
                return nil
            }
            return DuplicateGroup(fullHash: hash, original: original, copies: copies)
        }
        .sorted {
            if $0.reclaimableBytes == $1.reclaimableBytes {
                return $0.original.path.localizedStandardCompare($1.original.path) == .orderedAscending
            }
            return $0.reclaimableBytes > $1.reclaimableBytes
        }

        progress?(DuplicateScanProgress(
            phase: .completed,
            currentPath: nil,
            discoveredFileCount: files.count,
            candidateFileCount: fullCandidates.count,
            hashedFileCount: fullOutcomes.count
        ))

        return DuplicateScanReport(
            rootPath: rootURL.path,
            scannedAt: startedAt,
            durationSeconds: Date().timeIntervalSince(startedAt),
            discoveredFileCount: files.count,
            groups: groups,
            deferredLargeCandidates: deferredLargeCandidates,
            issues: issues
        )
    }

    private func enumerateFiles(
        rootURL: URL,
        maxFiles: Int,
        issues: inout [DuplicateScanIssue],
        progress: (@Sendable (DuplicateScanProgress) -> Void)?
    ) throws -> [DuplicateFile] {
        var enumerationIssues: [DuplicateScanIssue] = []
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { url, error in
                enumerationIssues.append(DuplicateScanIssue(path: url.path, message: error.localizedDescription))
                return true
            }
        ) else {
            throw DuplicateFinderError.rootIsUnavailable
        }

        var files: [DuplicateFile] = []
        for case let url as URL in enumerator {
            try Task.checkCancellation()
            if files.count >= maxFiles {
                enumerationIssues.append(DuplicateScanIssue(
                    path: rootURL.path,
                    message: "The duplicate scan reached its file-count safety limit."
                ))
                break
            }

            guard let file = duplicateFile(at: url) else {
                continue
            }
            files.append(file)
            if files.count == 1 || files.count.isMultiple(of: 250) {
                progress?(DuplicateScanProgress(
                    phase: .enumerating,
                    currentPath: file.path,
                    discoveredFileCount: files.count,
                    candidateFileCount: 0,
                    hashedFileCount: 0
                ))
            }
        }
        issues.append(contentsOf: enumerationIssues)
        return files
    }

    private func duplicateFile(at url: URL) -> DuplicateFile? {
        guard let values = try? url.resourceValues(forKeys: resourceKeys),
              values.isRegularFile == true,
              values.isSymbolicLink != true,
              let fileSize = values.fileSize,
              fileSize > 0 else {
            return nil
        }

        var fileInfo = stat()
        guard url.path.withCString({ lstat($0, &fileInfo) }) == 0 else {
            return nil
        }

        return DuplicateFile(
            path: url.standardizedFileURL.path,
            name: url.lastPathComponent,
            sizeBytes: Int64(fileSize),
            createdAt: values.creationDate,
            modifiedAt: values.contentModificationDate,
            deviceID: UInt64(bitPattern: Int64(fileInfo.st_dev)),
            inode: UInt64(fileInfo.st_ino)
        )
    }

    private enum HashStage: Sendable {
        case partial
        case full
    }

    private struct HashMatch: Sendable {
        let file: DuplicateFile
        let hash: String
    }

    private struct HashOutcome: Sendable {
        let success: HashMatch?
        let issue: DuplicateScanIssue?
    }

    private func hashFiles(
        _ files: [DuplicateFile],
        stage: HashStage,
        options: DuplicateScanOptions,
        phase: DuplicateScanPhase,
        discoveredFileCount: Int,
        progress: (@Sendable (DuplicateScanProgress) -> Void)?
    ) async throws -> [HashOutcome] {
        guard !files.isEmpty else {
            progress?(DuplicateScanProgress(
                phase: phase,
                currentPath: nil,
                discoveredFileCount: discoveredFileCount,
                candidateFileCount: 0,
                hashedFileCount: 0
            ))
            return []
        }

        return try await withThrowingTaskGroup(of: HashOutcome.self) { group in
            var iterator = files.makeIterator()
            var submittedCount = 0
            var completedCount = 0
            var outcomes: [HashOutcome] = []

            while submittedCount < options.maxConcurrentHashes, let file = iterator.next() {
                submittedCount += 1
                group.addTask {
                    try Self.hashOutcome(file: file, stage: stage, options: options)
                }
            }

            while let outcome = try await group.next() {
                try Task.checkCancellation()
                completedCount += 1
                outcomes.append(outcome)
                progress?(DuplicateScanProgress(
                    phase: phase,
                    currentPath: outcome.success?.file.path ?? outcome.issue?.path,
                    discoveredFileCount: discoveredFileCount,
                    candidateFileCount: files.count,
                    hashedFileCount: completedCount
                ))

                if let file = iterator.next() {
                    group.addTask {
                        try Self.hashOutcome(file: file, stage: stage, options: options)
                    }
                }
            }
            return outcomes
        }
    }

    private static func hashOutcome(
        file: DuplicateFile,
        stage: HashStage,
        options: DuplicateScanOptions
    ) throws -> HashOutcome {
        do {
            let hash = try hash(file: file, stage: stage, options: options)
            return HashOutcome(success: HashMatch(file: file, hash: hash), issue: nil)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return HashOutcome(
                success: nil,
                issue: DuplicateScanIssue(path: file.path, message: error.localizedDescription)
            )
        }
    }

    private static func hash(
        file: DuplicateFile,
        stage: HashStage,
        options: DuplicateScanOptions
    ) throws -> String {
        let url = URL(fileURLWithPath: file.path)
        let before = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
        guard before.isRegularFile == true, Int64(before.fileSize ?? -1) == file.sizeBytes else {
            throw CocoaError(.fileReadUnknown)
        }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let byteLimit: Int64? = stage == .partial ? Int64(options.partialHashByteCount) : nil
        var remaining = byteLimit
        var totalRead: Int64 = 0
        var hasher = SHA256()

        while remaining == nil || (remaining ?? 0) > 0 {
            try Task.checkCancellation()
            let requestSize = Int(min(
                Int64(options.fullHashChunkByteCount),
                remaining ?? Int64(options.fullHashChunkByteCount)
            ))
            guard requestSize > 0,
                  let data = try handle.read(upToCount: requestSize),
                  !data.isEmpty else {
                break
            }
            hasher.update(data: data)
            totalRead += Int64(data.count)
            if remaining != nil {
                remaining = max(0, (remaining ?? 0) - Int64(data.count))
            }
        }

        if stage == .full {
            guard totalRead == file.sizeBytes else {
                throw CocoaError(.fileReadUnknown)
            }
            let after = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            guard Int64(after.fileSize ?? -1) == file.sizeBytes,
                  file.modifiedAt == nil || after.contentModificationDate == file.modifiedAt else {
                throw CocoaError(.fileReadUnknown)
            }
        }

        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private struct FileIdentity: Hashable {
        let deviceID: UInt64
        let inode: UInt64
    }

    private static func removingHardLinks(_ files: [DuplicateFile]) -> [DuplicateFile] {
        var seen: Set<FileIdentity> = []
        return files
            .sorted { $0.path.localizedStandardCompare($1.path) == .orderedAscending }
            .filter { file in
                guard file.inode != 0 else {
                    return true
                }
                return seen.insert(FileIdentity(deviceID: file.deviceID, inode: file.inode)).inserted
            }
    }

    public static func chooseOriginal(from files: [DuplicateFile]) -> DuplicateFile {
        precondition(!files.isEmpty)
        return files.min(by: isMoreOriginal) ?? files[0]
    }

    private static func isMoreOriginal(_ left: DuplicateFile, _ right: DuplicateFile) -> Bool {
        let leftLooksLikeCopy = isLikelyCopyPath(left.path)
        let rightLooksLikeCopy = isLikelyCopyPath(right.path)
        if leftLooksLikeCopy != rightLooksLikeCopy {
            return !leftLooksLikeCopy
        }

        let leftDepth = URL(fileURLWithPath: left.path).pathComponents.count
        let rightDepth = URL(fileURLWithPath: right.path).pathComponents.count
        if leftDepth != rightDepth {
            return leftDepth < rightDepth
        }

        let leftDate = left.createdAt ?? left.modifiedAt ?? .distantFuture
        let rightDate = right.createdAt ?? right.modifiedAt ?? .distantFuture
        if leftDate != rightDate {
            return leftDate < rightDate
        }
        return left.path.localizedStandardCompare(right.path) == .orderedAscending
    }

    private static func isLikelyCopyPath(_ path: String) -> Bool {
        let normalized = path.lowercased()
        let markers = ["/backup", " copy", "(copy", " (1)", " (2)", " (3)", " 2."]
        return markers.contains { normalized.contains($0) }
    }

    private static func largerFileFirst(_ left: DuplicateFile, _ right: DuplicateFile) -> Bool {
        if left.sizeBytes == right.sizeBytes {
            return left.path.localizedStandardCompare(right.path) == .orderedAscending
        }
        return left.sizeBytes > right.sizeBytes
    }
}
