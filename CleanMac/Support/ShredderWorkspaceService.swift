import AppKit

@MainActor
enum ShredderWorkspaceService {
    static func chooseFiles() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.canCreateDirectories = false
        panel.treatsFilePackagesAsDirectories = false
        panel.prompt = L.t("shredder.picker.confirm")
        panel.message = L.t("shredder.picker.message")

        guard panel.runModal() == .OK else {
            return []
        }
        return panel.urls.map(\.standardizedFileURL)
    }
}
