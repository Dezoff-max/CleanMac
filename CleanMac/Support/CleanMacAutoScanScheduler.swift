import CleanMacCore
import Foundation

final class CleanMacAutoScanScheduler {
    private let defaults: UserDefaults
    private var timer: Timer?
    private var scanTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func start() {
        defaults.set(false, forKey: CleanMacPreferenceKeys.scanInProgress)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.evaluateSchedule()
        }
        evaluateSchedule()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        scanTask?.cancel()
        scanTask = nil
        defaults.set(false, forKey: CleanMacPreferenceKeys.scanInProgress)
    }

    private func evaluateSchedule(now: Date = Date(), calendar: Calendar = .current) {
        guard defaults.bool(forKey: CleanMacPreferenceKeys.autoScanEnabled) else {
            return
        }
        guard scanTask == nil else {
            return
        }
        guard !defaults.bool(forKey: CleanMacPreferenceKeys.scanInProgress) else {
            return
        }

        guard let dueRun = CleanMacScanSchedule.dueRun(defaults: defaults, now: now, calendar: calendar) else {
            return
        }

        let categories = CleanMacScanPreferences.selectedCategories(defaults: defaults)
        guard !categories.isEmpty else {
            return
        }

        runScan(categories: categories, runKey: dueRun.key)
    }

    private func runScan(categories: [CleanupCategory], runKey: String) {
        defaults.set(true, forKey: CleanMacPreferenceKeys.scanInProgress)

        scanTask = Task { [weak self] in
            let report = await Task.detached(priority: .utility) {
                CleanupScanner().scan(categories: categories)
            }.value

            guard let self else {
                return
            }
            guard !Task.isCancelled else {
                return
            }

            self.defaults.set(runKey, forKey: CleanMacPreferenceKeys.autoScanLastRunKey)
            CleanMacScanPreferences.storeLastScan(report, source: .scheduled, defaults: self.defaults)
            self.defaults.set(false, forKey: CleanMacPreferenceKeys.scanInProgress)
            self.scanTask = nil
        }
    }
}
