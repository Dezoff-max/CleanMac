import AppKit

@MainActor
enum DiskAnalysisWorkspaceService {
    static func chooseFolder() -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.prompt = L.t("disk.source.choose.confirm")
        panel.message = L.t("disk.source.choose.message")
        return panel.runModal() == .OK ? panel.url?.resolvingSymlinksInPath().standardizedFileURL : nil
    }

    static func reveal(_ url: URL) async {
        let revealedWithAutomation = await CleanMacAutomationService.revealInFinder(url)
        if !revealedWithAutomation {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @discardableResult
    static func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
