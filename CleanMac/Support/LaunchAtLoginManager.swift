import Combine
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    struct Failure: Equatable {
        let enabling: Bool
        let systemMessage: String
    }

    static let shared = LaunchAtLoginManager()

    @Published private(set) var status: SMAppService.Status
    @Published private(set) var isBusy = false
    @Published private(set) var lastFailure: Failure?

    var isRequested: Bool {
        status == .enabled || status == .requiresApproval
    }

    private init() {
        status = SMAppService.mainApp.status
    }

    func refresh(clearFailure: Bool = false) {
        status = SMAppService.mainApp.status
        if clearFailure {
            lastFailure = nil
        }
    }

    func setEnabled(_ enabled: Bool) async {
        guard !isBusy, enabled != isRequested else {
            return
        }

        isBusy = true
        lastFailure = nil

        let failureMessage = await Task.detached(priority: .userInitiated) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return nil as String?
            } catch {
                return error.localizedDescription
            }
        }.value

        status = SMAppService.mainApp.status
        if let failureMessage {
            lastFailure = Failure(enabling: enabled, systemMessage: failureMessage)
        }
        isBusy = false
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
