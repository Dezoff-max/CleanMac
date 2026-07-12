import Foundation

public enum DiskAnalysisFileType: String, CaseIterable, Sendable {
    case document
    case image
    case video
    case audio
    case archive
    case application
    case code
    case diskImage
    case other

    public static func classify(pathExtension: String) -> DiskAnalysisFileType {
        switch pathExtension.lowercased() {
        case "pdf", "doc", "docx", "pages", "rtf", "txt", "odt", "xls", "xlsx", "numbers", "csv", "ppt", "pptx", "key":
            .document
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp", "svg":
            .image
        case "mp4", "mov", "avi", "mkv", "wmv", "webm", "m4v":
            .video
        case "mp3", "wav", "flac", "aac", "m4a", "ogg", "wma":
            .audio
        case "zip", "gz", "tar", "rar", "7z", "bz2", "xz", "xip":
            .archive
        case "app", "pkg", "mpkg":
            .application
        case "swift", "h", "m", "mm", "c", "cpp", "py", "js", "ts", "java", "rs", "go", "rb", "php", "css", "html", "sh", "json", "xml", "yaml", "yml", "toml", "plist":
            .code
        case "dmg", "iso", "img", "sparseimage":
            .diskImage
        default:
            .other
        }
    }
}

public struct DiskAnalysisFile: Identifiable, Equatable, Sendable {
    public let id: String
    public let path: String
    public let name: String
    public let sizeBytes: Int64
    public let modifiedAt: Date?
    public let fileType: DiskAnalysisFileType

    public init(
        path: String,
        name: String,
        sizeBytes: Int64,
        modifiedAt: Date?,
        fileType: DiskAnalysisFileType
    ) {
        self.id = path
        self.path = path
        self.name = name
        self.sizeBytes = max(0, sizeBytes)
        self.modifiedAt = modifiedAt
        self.fileType = fileType
    }
}

public struct DiskAnalysisNode: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let path: String?
    public let sizeBytes: Int64
    public let isDirectory: Bool
    public let isAggregate: Bool
    public let children: [DiskAnalysisNode]

    public init(
        id: String,
        name: String,
        path: String?,
        sizeBytes: Int64,
        isDirectory: Bool,
        isAggregate: Bool = false,
        children: [DiskAnalysisNode] = []
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.sizeBytes = max(0, sizeBytes)
        self.isDirectory = isDirectory
        self.isAggregate = isAggregate
        self.children = children
    }
}

public enum DiskAnalysisProgressPhase: String, Sendable {
    case preparing
    case scanning
    case summarizing
    case completed
}

public struct DiskAnalysisProgress: Equatable, Sendable {
    public let phase: DiskAnalysisProgressPhase
    public let currentPath: String?
    public let visitedItemCount: Int
    public let measuredSizeBytes: Int64
    public let largeFileCount: Int

    public init(
        phase: DiskAnalysisProgressPhase,
        currentPath: String?,
        visitedItemCount: Int,
        measuredSizeBytes: Int64,
        largeFileCount: Int
    ) {
        self.phase = phase
        self.currentPath = currentPath
        self.visitedItemCount = max(0, visitedItemCount)
        self.measuredSizeBytes = max(0, measuredSizeBytes)
        self.largeFileCount = max(0, largeFileCount)
    }
}

public struct DiskAnalysisIssue: Equatable, Sendable {
    public let path: String
    public let message: String

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}

public struct DiskAnalysisReport: Equatable, Sendable {
    public let root: DiskAnalysisNode
    public let largeFiles: [DiskAnalysisFile]
    public let issues: [DiskAnalysisIssue]
    public let visitedItemCount: Int
    public let durationSeconds: TimeInterval

    public init(
        root: DiskAnalysisNode,
        largeFiles: [DiskAnalysisFile],
        issues: [DiskAnalysisIssue],
        visitedItemCount: Int,
        durationSeconds: TimeInterval
    ) {
        self.root = root
        self.largeFiles = largeFiles
        self.issues = issues
        self.visitedItemCount = max(0, visitedItemCount)
        self.durationSeconds = max(0, durationSeconds)
    }
}

public struct DiskAnalysisOptions: Equatable, Sendable {
    public var minimumLargeFileSizeBytes: Int64
    public var maximumLargeFiles: Int
    public var maximumTreeDepth: Int
    public var maximumChildrenPerNode: Int
    public var maximumTreeNodes: Int
    public var progressInterval: Int

    public init(
        minimumLargeFileSizeBytes: Int64 = 50 * 1024 * 1024,
        maximumLargeFiles: Int = 5_000,
        maximumTreeDepth: Int = 6,
        maximumChildrenPerNode: Int = 18,
        maximumTreeNodes: Int = 5_000,
        progressInterval: Int = 200
    ) {
        self.minimumLargeFileSizeBytes = max(1, minimumLargeFileSizeBytes)
        self.maximumLargeFiles = max(1, maximumLargeFiles)
        self.maximumTreeDepth = max(1, maximumTreeDepth)
        self.maximumChildrenPerNode = max(2, maximumChildrenPerNode)
        self.maximumTreeNodes = max(32, maximumTreeNodes)
        self.progressInterval = max(1, progressInterval)
    }
}

public enum DiskAnalyzerError: Error, Equatable, Sendable {
    case rootUnavailable
    case rootIsNotDirectory
    case enumerationFailed
}

public struct DiskAnalyzer {
    private let fileManager: FileManager

    private let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isRegularFileKey,
        .isSymbolicLinkKey,
        .fileSizeKey,
        .fileAllocatedSizeKey,
        .totalFileAllocatedSizeKey,
        .contentModificationDateKey,
        .nameKey
    ]

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Performs a read-only recursive scan. The returned tree is deliberately
    /// bounded; file rows are separate and never become cleanup candidates.
    public func scan(
        root rootURL: URL,
        options: DiskAnalysisOptions = DiskAnalysisOptions(),
        progress: (@Sendable (DiskAnalysisProgress) -> Void)? = nil,
        isCancelled: @Sendable () -> Bool = { false }
    ) throws -> DiskAnalysisReport {
        let startedAt = Date()
        let canonicalRoot = rootURL.resolvingSymlinksInPath().standardizedFileURL
        var rootIsDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: canonicalRoot.path, isDirectory: &rootIsDirectory) else {
            throw DiskAnalyzerError.rootUnavailable
        }
        guard rootIsDirectory.boolValue else {
            throw DiskAnalyzerError.rootIsNotDirectory
        }

        try checkCancellation(isCancelled)
        progress?(DiskAnalysisProgress(
            phase: .preparing,
            currentPath: canonicalRoot.path,
            visitedItemCount: 0,
            measuredSizeBytes: 0,
            largeFileCount: 0
        ))

        let rootName = canonicalRoot.lastPathComponent.isEmpty ? canonicalRoot.path : canonicalRoot.lastPathComponent
        let rootAccumulator = NodeAccumulator(
            name: rootName,
            path: canonicalRoot.path,
            isDirectory: true
        )
        var treeNodeCount = 1
        var visitedItemCount = 0
        var totalSizeBytes: Int64 = 0
        var largeFiles: [DiskAnalysisFile] = []
        var issues: [DiskAnalysisIssue] = []

        guard let enumerator = fileManager.enumerator(
            at: canonicalRoot,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [],
            errorHandler: { url, error in
                issues.append(DiskAnalysisIssue(path: url.path, message: error.localizedDescription))
                return true
            }
        ) else {
            throw DiskAnalyzerError.enumerationFailed
        }

        while let entry = enumerator.nextObject() as? URL {
            try checkCancellation(isCancelled)
            visitedItemCount += 1

            guard let values = try? entry.resourceValues(forKeys: resourceKeys) else {
                issues.append(DiskAnalysisIssue(path: entry.path, message: "Metadata unavailable"))
                continue
            }

            if values.isSymbolicLink == true {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            let relativeComponents = relativePathComponents(of: entry, beneath: canonicalRoot)
            if values.isDirectory == true {
                registerDirectory(
                    components: relativeComponents,
                    rootURL: canonicalRoot,
                    rootAccumulator: rootAccumulator,
                    maximumDepth: options.maximumTreeDepth,
                    maximumNodes: options.maximumTreeNodes,
                    treeNodeCount: &treeNodeCount
                )
            } else if values.isRegularFile == true {
                let sizeBytes = allocatedSize(from: values)
                totalSizeBytes += sizeBytes
                addFileSize(
                    sizeBytes,
                    directoryComponents: Array(relativeComponents.dropLast()),
                    rootURL: canonicalRoot,
                    rootAccumulator: rootAccumulator,
                    maximumDepth: options.maximumTreeDepth,
                    maximumNodes: options.maximumTreeNodes,
                    treeNodeCount: &treeNodeCount
                )

                if sizeBytes >= options.minimumLargeFileSizeBytes {
                    largeFiles.append(DiskAnalysisFile(
                        path: entry.path,
                        name: values.name ?? entry.lastPathComponent,
                        sizeBytes: sizeBytes,
                        modifiedAt: values.contentModificationDate,
                        fileType: .classify(pathExtension: entry.pathExtension)
                    ))
                }
            }

            if visitedItemCount.isMultiple(of: options.progressInterval) {
                progress?(DiskAnalysisProgress(
                    phase: .scanning,
                    currentPath: entry.path,
                    visitedItemCount: visitedItemCount,
                    measuredSizeBytes: totalSizeBytes,
                    largeFileCount: largeFiles.count
                ))
            }
        }

        try checkCancellation(isCancelled)
        progress?(DiskAnalysisProgress(
            phase: .summarizing,
            currentPath: canonicalRoot.path,
            visitedItemCount: visitedItemCount,
            measuredSizeBytes: totalSizeBytes,
            largeFileCount: largeFiles.count
        ))

        let sortedLargeFiles = largeFiles
            .sorted {
                if $0.sizeBytes == $1.sizeBytes {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.sizeBytes > $1.sizeBytes
            }
            .prefix(options.maximumLargeFiles)

        let rootNode = finalize(
            rootAccumulator,
            maximumChildren: options.maximumChildrenPerNode,
            depth: 0
        )

        progress?(DiskAnalysisProgress(
            phase: .completed,
            currentPath: canonicalRoot.path,
            visitedItemCount: visitedItemCount,
            measuredSizeBytes: rootNode.sizeBytes,
            largeFileCount: sortedLargeFiles.count
        ))

        return DiskAnalysisReport(
            root: rootNode,
            largeFiles: Array(sortedLargeFiles),
            issues: issues,
            visitedItemCount: visitedItemCount,
            durationSeconds: Date().timeIntervalSince(startedAt)
        )
    }

    private func checkCancellation(_ isCancelled: @Sendable () -> Bool) throws {
        if isCancelled() {
            throw CancellationError()
        }
    }

    private func relativePathComponents(of url: URL, beneath rootURL: URL) -> [String] {
        let rootComponents = rootURL.standardizedFileURL.pathComponents
        let entryComponents = url.standardizedFileURL.pathComponents
        guard entryComponents.starts(with: rootComponents) else {
            return []
        }
        return Array(entryComponents.dropFirst(rootComponents.count))
    }

    private func registerDirectory(
        components: [String],
        rootURL: URL,
        rootAccumulator: NodeAccumulator,
        maximumDepth: Int,
        maximumNodes: Int,
        treeNodeCount: inout Int
    ) {
        var current = rootAccumulator
        var currentURL = rootURL

        for component in components.prefix(maximumDepth) {
            currentURL.append(path: component, directoryHint: .isDirectory)
            guard let child = ensureDirectory(
                name: component,
                url: currentURL,
                parent: current,
                rootAccumulator: rootAccumulator,
                maximumNodes: maximumNodes,
                treeNodeCount: &treeNodeCount
            ) else {
                return
            }
            current = child
        }
    }

    private func addFileSize(
        _ sizeBytes: Int64,
        directoryComponents: [String],
        rootURL: URL,
        rootAccumulator: NodeAccumulator,
        maximumDepth: Int,
        maximumNodes: Int,
        treeNodeCount: inout Int
    ) {
        rootAccumulator.sizeBytes += sizeBytes
        var current = rootAccumulator
        var currentURL = rootURL

        for component in directoryComponents.prefix(maximumDepth) {
            currentURL.append(path: component, directoryHint: .isDirectory)
            guard let child = ensureDirectory(
                name: component,
                url: currentURL,
                parent: current,
                rootAccumulator: rootAccumulator,
                maximumNodes: maximumNodes,
                treeNodeCount: &treeNodeCount
            ) else {
                current.unmappedSizeBytes += sizeBytes
                return
            }
            child.sizeBytes += sizeBytes
            current = child
        }

        if directoryComponents.count > maximumDepth {
            current.unmappedSizeBytes += sizeBytes
        } else {
            current.directFileSizeBytes += sizeBytes
        }
    }

    private func ensureDirectory(
        name: String,
        url: URL,
        parent: NodeAccumulator,
        rootAccumulator: NodeAccumulator,
        maximumNodes: Int,
        treeNodeCount: inout Int
    ) -> NodeAccumulator? {
        if let existing = parent.children[url.path] {
            return existing
        }
        // Directory enumeration is depth-first. Reserve a bounded set of root
        // children even after the deeper-node budget is spent, otherwise one
        // early subtree (for example Library) can collapse every later home
        // folder into the root's "Other" segment.
        let isRootChild = parent === rootAccumulator
        let canUseRootReserve = isRootChild && parent.children.count < 512
        guard treeNodeCount < maximumNodes || canUseRootReserve else {
            return nil
        }

        let child = NodeAccumulator(name: name, path: url.path, isDirectory: true)
        parent.children[url.path] = child
        treeNodeCount += 1
        return child
    }

    private func finalize(
        _ accumulator: NodeAccumulator,
        maximumChildren: Int,
        depth: Int
    ) -> DiskAnalysisNode {
        var children = accumulator.children.values
            .filter { $0.sizeBytes > 0 }
            .sorted {
                if $0.sizeBytes == $1.sizeBytes {
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return $0.sizeBytes > $1.sizeBytes
            }
            .map { finalize($0, maximumChildren: maximumChildren, depth: depth + 1) }

        if accumulator.directFileSizeBytes > 0 {
            children.append(DiskAnalysisNode(
                id: "\(accumulator.path ?? accumulator.name)#files",
                name: "Files",
                path: accumulator.path,
                sizeBytes: accumulator.directFileSizeBytes,
                isDirectory: false,
                isAggregate: true
            ))
        }

        if accumulator.unmappedSizeBytes > 0 {
            children.append(DiskAnalysisNode(
                id: "\(accumulator.path ?? accumulator.name)#unmapped",
                name: "Other",
                path: nil,
                sizeBytes: accumulator.unmappedSizeBytes,
                isDirectory: false,
                isAggregate: true
            ))
        }

        children.sort {
            if $0.sizeBytes == $1.sizeBytes {
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return $0.sizeBytes > $1.sizeBytes
        }

        if children.count > maximumChildren {
            let retainedCount = max(1, maximumChildren - 1)
            let retained = Array(children.prefix(retainedCount))
            let remainingSize = children.dropFirst(retainedCount).reduce(Int64(0)) { $0 + $1.sizeBytes }
            children = retained + [DiskAnalysisNode(
                id: "\(accumulator.path ?? accumulator.name)#other-\(depth)",
                name: "Other",
                path: nil,
                sizeBytes: remainingSize,
                isDirectory: false,
                isAggregate: true
            )]
        }

        return DiskAnalysisNode(
            id: accumulator.path ?? accumulator.name,
            name: accumulator.name,
            path: accumulator.path,
            sizeBytes: accumulator.sizeBytes,
            isDirectory: accumulator.isDirectory,
            children: children
        )
    }

    private func allocatedSize(from values: URLResourceValues) -> Int64 {
        if let totalFileAllocatedSize = values.totalFileAllocatedSize {
            return Int64(totalFileAllocatedSize)
        }
        if let fileAllocatedSize = values.fileAllocatedSize {
            return Int64(fileAllocatedSize)
        }
        if let fileSize = values.fileSize {
            return Int64(fileSize)
        }
        return 0
    }
}

private final class NodeAccumulator {
    let name: String
    let path: String?
    let isDirectory: Bool
    var sizeBytes: Int64 = 0
    var directFileSizeBytes: Int64 = 0
    var unmappedSizeBytes: Int64 = 0
    var children: [String: NodeAccumulator] = [:]

    init(name: String, path: String?, isDirectory: Bool) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
    }
}
