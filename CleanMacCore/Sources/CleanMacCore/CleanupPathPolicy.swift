import Foundation

struct CleanupRootResolver {
    let homeDirectory: URL
    let temporaryDirectory: URL

    func rootURL(for category: CleanupCategory) -> URL {
        switch category {
        case .userCaches:
            homeDirectory.appending(path: "Library/Caches", directoryHint: .isDirectory)
        case .logs:
            homeDirectory.appending(path: "Library/Logs", directoryHint: .isDirectory)
        case .temporaryFiles:
            temporaryDirectory
        case .trash:
            homeDirectory.appending(path: ".Trash", directoryHint: .isDirectory)
        case .downloads:
            homeDirectory.appending(path: "Downloads", directoryHint: .isDirectory)
        case .xcodeDerivedData:
            homeDirectory.appending(path: "Library/Developer/Xcode/DerivedData", directoryHint: .isDirectory)
        }
    }

    func canonicalRootPath(for category: CleanupCategory) -> String {
        rootURL(for: category).canonicalPath
    }
}

extension URL {
    var canonicalPath: String {
        resolvingSymlinksInPath().standardizedFileURL.path
    }
}
