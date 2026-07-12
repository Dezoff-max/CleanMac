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
        }
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
