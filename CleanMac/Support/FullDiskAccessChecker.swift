import Foundation

enum FullDiskAccessState: Equatable {
    case granted
    case limited
    case unknown
}

struct FullDiskAccessCheckResult: Equatable {
    let state: FullDiskAccessState
    let readableProbeCount: Int
    let availableProbeCount: Int
}

struct FullDiskAccessChecker {
    private let fileManager: FileManager
    private let homeDirectory: URL

    init(
        fileManager: FileManager = .default,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
    ) {
        self.fileManager = fileManager
        self.homeDirectory = homeDirectory
    }

    func check() -> FullDiskAccessCheckResult {
        let availableProbes = protectedProbeURLs.filter { fileManager.fileExists(atPath: $0.path) }
        guard !availableProbes.isEmpty else {
            return FullDiskAccessCheckResult(state: .unknown, readableProbeCount: 0, availableProbeCount: 0)
        }

        let readableCount = availableProbes.filter(canReadDirectoryMetadata).count
        let state: FullDiskAccessState = readableCount == availableProbes.count ? .granted : .limited

        return FullDiskAccessCheckResult(
            state: state,
            readableProbeCount: readableCount,
            availableProbeCount: availableProbes.count
        )
    }

    private var protectedProbeURLs: [URL] {
        [
            homeDirectory.appending(path: "Library/Mail", directoryHint: .isDirectory),
            homeDirectory.appending(path: "Library/Messages", directoryHint: .isDirectory),
            homeDirectory.appending(path: "Library/Safari", directoryHint: .isDirectory),
            homeDirectory.appending(path: "Library/Calendars", directoryHint: .isDirectory)
        ]
    }

    private func canReadDirectoryMetadata(_ url: URL) -> Bool {
        do {
            _ = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            return true
        } catch {
            return false
        }
    }
}
