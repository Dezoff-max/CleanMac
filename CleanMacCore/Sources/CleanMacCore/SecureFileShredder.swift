import Darwin
import Foundation

public struct SecureDeletionCandidate: Identifiable, Equatable, Sendable {
    public let path: String
    public let name: String
    public let sizeBytes: Int64
    public let fileSystemName: String

    let deviceID: UInt64
    let inode: UInt64
    let modificationSeconds: Int64
    let modificationNanoseconds: Int64

    public var id: String { path }

    public var isAPFS: Bool {
        fileSystemName.localizedCaseInsensitiveContains("apfs")
    }

    init(path: String, name: String, sizeBytes: Int64, fileSystemName: String, metadata: stat) {
        self.path = path
        self.name = name
        self.sizeBytes = max(0, sizeBytes)
        self.fileSystemName = fileSystemName
        self.deviceID = UInt64(metadata.st_dev)
        self.inode = UInt64(metadata.st_ino)
        self.modificationSeconds = Int64(metadata.st_mtimespec.tv_sec)
        self.modificationNanoseconds = Int64(metadata.st_mtimespec.tv_nsec)
    }
}

public enum SecureDeletionError: Error, Equatable, Sendable {
    case pathUnavailable
    case protectedPath
    case packageContent
    case symbolicLink
    case notRegularFile
    case multipleHardLinks
    case fileChanged
    case fileBusy
    case openFailed(Int32)
    case writeFailed(Int32)
    case syncFailed(Int32)
    case truncateFailed(Int32)
    case removeFailed(Int32)
}

public struct SecureFileShredder: Sendable {
    private static let bufferSize = 1024 * 1024

    private static let protectedRoots = [
        "/System",
        "/Library",
        "/Applications",
        "/bin",
        "/sbin",
        "/usr",
        "/etc",
        "/var/db",
        "/var/root",
        "/var/vm",
        "/private/etc",
        "/private/var/db",
        "/private/var/root",
        "/private/var/vm",
        "/opt"
    ]

    private static let packageExtensions = [
        "app", "appex", "bundle", "framework", "plugin", "xpc", "pkg", "mpkg"
    ]

    private let beforeUnlink: @Sendable (String) throws -> Void

    public init() {
        self.beforeUnlink = { _ in }
    }

    init(beforeUnlink: @escaping @Sendable (String) throws -> Void) {
        self.beforeUnlink = beforeUnlink
    }

    public func inspect(url: URL) throws -> SecureDeletionCandidate {
        let standardizedURL = url.standardizedFileURL
        let path = standardizedURL.path

        guard !path.isEmpty else {
            throw SecureDeletionError.pathUnavailable
        }

        var metadata = stat()
        guard path.withCString({ Darwin.lstat($0, &metadata) }) == 0 else {
            throw SecureDeletionError.pathUnavailable
        }

        let fileType = metadata.st_mode & mode_t(S_IFMT)
        guard fileType != mode_t(S_IFLNK) else {
            throw SecureDeletionError.symbolicLink
        }
        guard fileType == mode_t(S_IFREG) else {
            throw SecureDeletionError.notRegularFile
        }
        guard metadata.st_nlink == 1 else {
            throw SecureDeletionError.multipleHardLinks
        }

        let canonicalURL = standardizedURL.resolvingSymlinksInPath().standardizedFileURL
        guard !Self.isProtected(path: path), !Self.isProtected(path: canonicalURL.path) else {
            throw SecureDeletionError.protectedPath
        }
        guard !Self.isInsidePackage(url: standardizedURL), !Self.isInsidePackage(url: canonicalURL) else {
            throw SecureDeletionError.packageContent
        }

        let volumeValues = try? standardizedURL.resourceValues(forKeys: [.volumeLocalizedFormatDescriptionKey])
        let fileSystemName = volumeValues?.volumeLocalizedFormatDescription ?? "Unknown"

        return SecureDeletionCandidate(
            path: path,
            name: standardizedURL.lastPathComponent,
            sizeBytes: Int64(metadata.st_size),
            fileSystemName: fileSystemName,
            metadata: metadata
        )
    }

    @discardableResult
    public func shred(_ candidate: SecureDeletionCandidate) throws -> Int64 {
        let candidateURL = URL(fileURLWithPath: candidate.path).standardizedFileURL
        let canonicalURL = candidateURL.resolvingSymlinksInPath().standardizedFileURL
        guard !Self.isProtected(path: candidate.path), !Self.isProtected(path: canonicalURL.path) else {
            throw SecureDeletionError.protectedPath
        }
        guard !Self.isInsidePackage(url: candidateURL), !Self.isInsidePackage(url: canonicalURL) else {
            throw SecureDeletionError.packageContent
        }

        let descriptor = candidate.path.withCString {
            Darwin.open($0, O_WRONLY | O_NOFOLLOW | O_CLOEXEC)
        }
        guard descriptor >= 0 else {
            throw SecureDeletionError.openFailed(errno)
        }
        defer { Darwin.close(descriptor) }

        guard Darwin.lockf(descriptor, F_TLOCK, 0) == 0 else {
            throw SecureDeletionError.fileBusy
        }
        defer { Darwin.lockf(descriptor, F_ULOCK, 0) }

        var openedMetadata = stat()
        guard Darwin.fstat(descriptor, &openedMetadata) == 0 else {
            throw SecureDeletionError.openFailed(errno)
        }
        try validate(candidate: candidate, metadata: openedMetadata, includeMutableMetadata: true)

        if candidate.sizeBytes > 0 {
            try overwrite(descriptor: descriptor, byteCount: candidate.sizeBytes)
            guard Darwin.fsync(descriptor) == 0 else {
                throw SecureDeletionError.syncFailed(errno)
            }
        }

        try beforeUnlink(candidate.path)

        guard Darwin.ftruncate(descriptor, 0) == 0 else {
            throw SecureDeletionError.truncateFailed(errno)
        }
        guard Darwin.fsync(descriptor) == 0 else {
            throw SecureDeletionError.syncFailed(errno)
        }

        var pathMetadata = stat()
        guard candidate.path.withCString({ Darwin.lstat($0, &pathMetadata) }) == 0 else {
            throw SecureDeletionError.fileChanged
        }
        try validate(candidate: candidate, metadata: pathMetadata, includeMutableMetadata: false)

        guard candidate.path.withCString({ Darwin.unlink($0) }) == 0 else {
            throw SecureDeletionError.removeFailed(errno)
        }

        return candidate.sizeBytes
    }

    private func overwrite(descriptor: Int32, byteCount: Int64) throws {
        guard Darwin.lseek(descriptor, 0, SEEK_SET) >= 0 else {
            throw SecureDeletionError.writeFailed(errno)
        }

        var remaining = byteCount
        var buffer = [UInt8](repeating: 0, count: Self.bufferSize)

        while remaining > 0 {
            let chunkSize = min(Int64(buffer.count), remaining)
            buffer.withUnsafeMutableBytes { bytes in
                if let baseAddress = bytes.baseAddress {
                    arc4random_buf(baseAddress, Int(chunkSize))
                }
            }

            var written = 0
            while written < Int(chunkSize) {
                let result = buffer.withUnsafeBytes { bytes in
                    Darwin.write(
                        descriptor,
                        bytes.baseAddress!.advanced(by: written),
                        Int(chunkSize) - written
                    )
                }

                if result < 0 {
                    if errno == EINTR {
                        continue
                    }
                    throw SecureDeletionError.writeFailed(errno)
                }
                guard result > 0 else {
                    throw SecureDeletionError.writeFailed(EIO)
                }
                written += result
            }

            remaining -= chunkSize
        }
    }

    private func validate(
        candidate: SecureDeletionCandidate,
        metadata: stat,
        includeMutableMetadata: Bool
    ) throws {
        let fileType = metadata.st_mode & mode_t(S_IFMT)
        guard fileType != mode_t(S_IFLNK) else {
            throw SecureDeletionError.symbolicLink
        }
        guard fileType == mode_t(S_IFREG) else {
            throw SecureDeletionError.notRegularFile
        }
        guard metadata.st_nlink == 1 else {
            throw SecureDeletionError.multipleHardLinks
        }
        guard UInt64(metadata.st_dev) == candidate.deviceID,
              UInt64(metadata.st_ino) == candidate.inode else {
            throw SecureDeletionError.fileChanged
        }

        if includeMutableMetadata {
            guard Int64(metadata.st_size) == candidate.sizeBytes,
                  Int64(metadata.st_mtimespec.tv_sec) == candidate.modificationSeconds,
                  Int64(metadata.st_mtimespec.tv_nsec) == candidate.modificationNanoseconds else {
                throw SecureDeletionError.fileChanged
            }
        }
    }

    private static func isProtected(path: String) -> Bool {
        protectedRoots.contains { root in
            path == root || path.hasPrefix(root + "/")
        }
    }

    private static func isInsidePackage(url: URL) -> Bool {
        url.pathComponents.contains { component in
            let pathExtension = URL(fileURLWithPath: component).pathExtension.lowercased()
            return packageExtensions.contains(pathExtension)
        }
    }
}
