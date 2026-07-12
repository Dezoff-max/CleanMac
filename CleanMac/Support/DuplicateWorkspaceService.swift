import AppKit
import CleanMacCore

@MainActor
enum DuplicateWorkspaceService {
    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = L.t("duplicates.source.choose.confirm")
        panel.message = L.t("duplicates.source.choose.message")
        return panel.runModal() == .OK
            ? panel.url?.resolvingSymlinksInPath().standardizedFileURL
            : nil
    }

    static func reveal(_ file: DuplicateFile) async {
        let url = URL(fileURLWithPath: file.path)
        let revealedWithAutomation = await CleanMacAutomationService.revealInFinder(url)
        if !revealedWithAutomation {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}
