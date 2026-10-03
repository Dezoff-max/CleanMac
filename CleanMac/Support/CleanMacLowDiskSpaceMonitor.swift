import Foundation

@MainActor
final class CleanMacLowDiskSpaceMonitor {
    private let checkInterval: Duration
    private var monitoringTask: Task<Void, Never>?

    init(checkInterval: Duration = .seconds(30 * 60)) {
        self.checkInterval = checkInterval
    }

    func start() {
        guard monitoringTask == nil else {
            return
        }

        monitoringTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                do {
                    let disk = try await StatusDiskSnapshotReader.shared.snapshot()
                    try Task.checkCancellation()
                    await CleanMacNotificationService.notifyLowDiskSpaceIfNeeded(disk)
                    try await Task.sleep(for: checkInterval)
                } catch {
                    return
                }
            }
        }
    }

    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }
}
