import Foundation

/// Capacity-for-important-usage may synchronously contact macOS services. Keep
/// that work off the main actor, and share one pending read across every window.
actor StatusDiskSnapshotReader {
    static let shared = StatusDiskSnapshotReader()

    private var inFlight: Task<StatusDiskSnapshot, Never>?
    private var cached: (snapshot: StatusDiskSnapshot, date: ContinuousClock.Instant)?

    func snapshot(forceRefresh: Bool = false) async throws -> StatusDiskSnapshot {
        try Task.checkCancellation()

        // A caller cancelling must not cancel a read another consumer is using.
        // The OS query itself is synchronous and cannot be interrupted safely.
        if let inFlight {
            let result = await inFlight.value
            try Task.checkCancellation()
            return result
        }

        if !forceRefresh, let cached,
           cached.date.duration(to: .now) < .seconds(30) {
            return cached.snapshot
        }

        let worker = Task.detached(priority: .utility) {
            StatusDiskSnapshot.current()
        }
        inFlight = worker
        let result = await worker.value
        // Only the caller that created this task clears it. Other waiters cannot
        // accidentally clear a newer read after actor reentrancy.
        inFlight = nil
        cached = (result, .now)
        try Task.checkCancellation()
        return result
    }
}
