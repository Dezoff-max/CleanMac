import Darwin
import Foundation

struct CleanupRootResolver {
    let homeDirectory: URL
    let temporaryDirectory: URL

    func rootURLs(for category: CleanupCategory) -> [URL] {
        switch category {
        case .userCaches:
            [homeDirectory.appending(path: "Library/Caches", directoryHint: .isDirectory)]
        case .browserCaches:
            [
                homeDirectory.appending(path: "Library/Caches/com.apple.Safari", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/Google", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/Firefox", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/Mozilla", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/BraveSoftware", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/Microsoft Edge", directoryHint: .isDirectory)
            ]
        case .nodePackageCaches:
            [
                homeDirectory.appending(path: ".npm", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/Yarn", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/pnpm", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/pnpm/store", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".cache/pnpm", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".cache/yarn", directoryHint: .isDirectory)
            ]
        case .swiftPackageBuilds:
            [homeDirectory.appending(path: "Library/Caches/org.swift.swiftpm", directoryHint: .isDirectory)]
        case .developerPackageCaches:
            [
                homeDirectory.appending(path: "Library/Caches/Homebrew", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/pip", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".cargo/registry/cache", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".cargo/registry/src", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".gradle/caches", directoryHint: .isDirectory)
            ]
        case .developerIDECaches:
            electronCacheRoots(for: "Cursor")
                + electronCacheRoots(for: "Code")
                + [
                    homeDirectory.appending(path: "Library/Caches/com.todesktop.230313mzl4w4u92", directoryHint: .isDirectory),
                    homeDirectory.appending(path: "Library/Caches/com.microsoft.VSCode", directoryHint: .isDirectory)
                ]
        case .developerAITemporaryFiles:
            [
                homeDirectory.appending(path: ".codex/.tmp", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".codex/tmp", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".codex/cache", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/com.openai.codex", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".claude/cache", directoryHint: .isDirectory),
                homeDirectory.appending(path: ".claude/paste-cache", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Caches/com.anthropic.claudefordesktop", directoryHint: .isDirectory)
            ]
        case .logs:
            [homeDirectory.appending(path: "Library/Logs", directoryHint: .isDirectory)]
        case .temporaryFiles:
            [temporaryDirectory]
        case .trash:
            [homeDirectory.appending(path: ".Trash", directoryHint: .isDirectory)]
        case .downloads:
            [homeDirectory.appending(path: "Downloads", directoryHint: .isDirectory)]
        case .downloadedInstallers:
            [homeDirectory.appending(path: "Downloads", directoryHint: .isDirectory)]
        case .xcodeDerivedData:
            [homeDirectory.appending(path: "Library/Developer/Xcode/DerivedData", directoryHint: .isDirectory)]
        case .xcodeDeviceSupport:
            [homeDirectory.appending(path: "Library/Developer/Xcode/iOS DeviceSupport", directoryHint: .isDirectory)]
        case .xcodePreviews:
            [homeDirectory.appending(path: "Library/Developer/Xcode/UserData/Previews", directoryHint: .isDirectory)]
        case .xcodeSimulatorData:
            [
                homeDirectory.appending(path: "Library/Developer/CoreSimulator/Devices", directoryHint: .isDirectory),
                homeDirectory.appending(path: "Library/Developer/CoreSimulator/Profiles/Runtimes", directoryHint: .isDirectory)
            ]
        case .xcodeArchives:
            [homeDirectory.appending(path: "Library/Developer/Xcode/Archives", directoryHint: .isDirectory)]
        }
    }

    private func electronCacheRoots(for applicationSupportName: String) -> [URL] {
        let base = homeDirectory.appending(
            path: "Library/Application Support/\(applicationSupportName)",
            directoryHint: .isDirectory
        )
        return ["Cache", "Code Cache", "GPUCache", "CachedData", "CachedProfilesData"]
            .map { base.appending(path: $0, directoryHint: .isDirectory) }
    }

    func rootURL(for category: CleanupCategory) -> URL {
        rootURLs(for: category)[0]
    }

    func canonicalRootPaths(for category: CleanupCategory) -> [String] {
        rootURLs(for: category).map(\.canonicalPath)
    }

    func canonicalRootPath(for category: CleanupCategory) -> String {
        canonicalRootPaths(for: category)[0]
    }
}

extension URL {
    var canonicalPath: String {
        let sourcePath = path
        if let resolvedPath = sourcePath.withCString({ realpath($0, nil) }) {
            defer { free(resolvedPath) }
            return String(cString: resolvedPath)
        }

        let parentURL = deletingLastPathComponent()
        if let resolvedParentPath = parentURL.path.withCString({ realpath($0, nil) }) {
            defer { free(resolvedParentPath) }
            return URL(fileURLWithPath: String(cString: resolvedParentPath))
                .appending(path: lastPathComponent)
                .path
        }

        return resolvingSymlinksInPath().standardizedFileURL.path
    }
}
