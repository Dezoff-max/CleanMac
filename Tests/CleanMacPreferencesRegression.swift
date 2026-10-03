import CleanMacCore
import Foundation

/// Records writes without touching the user's preferences or a persistent suite.
private final class CountingDefaults: UserDefaults, @unchecked Sendable {
    private var values: [String: Any]
    private(set) var writtenKeys: [String] = []

    init(values: [String: Any]) {
        self.values = values
        super.init(suiteName: "CleanMacPreferencesRegression")!
    }

    override func string(forKey defaultName: String) -> String? {
        values[defaultName] as? String
    }

    override func integer(forKey defaultName: String) -> Int {
        values[defaultName] as? Int ?? 0
    }

    override func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value
        writtenKeys.append(defaultName)
    }

    override func set(_ value: Int, forKey defaultName: String) {
        values[defaultName] = value
        writtenKeys.append(defaultName)
    }
}

@main
private struct CleanMacPreferencesRegression {
    static func main() {
        let selectionKey = CleanMacPreferenceKeys.selectedAreaIDs
        let schemaKey = CleanMacPreferenceKeys.selectedAreaSchemaVersion
        let defaultSelection = CleanMacScanPreferences.defaultSelectedAreaIDs

        // Exact preferences state of the frozen installed release. Recreating
        // the view must not keep writing preferences and invalidating the scene.
        let missingSelection = CountingDefaults(values: [schemaKey: 1])
        for _ in 0..<100 {
            expect(CleanMacScanPreferences.selectedAreaIDs(defaults: missingSelection) == defaultSelection,
                   "An absent selection must retain the catalog defaults")
        }
        expect(missingSelection.writtenKeys.isEmpty, "Current schema + absent selection must never write")
        print("PASS: absent selection/current schema: 100 reads, 0 writes")

        let emptySelection = CountingDefaults(values: [schemaKey: 1, selectionKey: ""])
        for _ in 0..<100 {
            expect(CleanMacScanPreferences.selectedAreaIDs(defaults: emptySelection).isEmpty,
                   "An explicitly empty selection must remain empty")
        }
        expect(emptySelection.writtenKeys.isEmpty, "Current schema + empty selection must never write")
        print("PASS: empty selection/current schema: 100 reads, 0 writes")

        let firstLaunch = CountingDefaults(values: [:])
        for _ in 0..<100 {
            expect(CleanMacScanPreferences.selectedAreaIDs(defaults: firstLaunch) == defaultSelection,
                   "First-launch reads must retain the catalog defaults")
        }
        expect(firstLaunch.writtenKeys == [schemaKey], "First launch must initialize the schema only once")
        print("PASS: first launch: 100 reads, 1 schema initialization")

        let oldEmptySelection = CountingDefaults(values: [selectionKey: ""])
        for _ in 0..<100 {
            expect(CleanMacScanPreferences.selectedAreaIDs(defaults: oldEmptySelection).isEmpty,
                   "Migration must preserve an explicit empty selection")
        }
        expect(oldEmptySelection.writtenKeys == [schemaKey], "Empty-selection schema migration must run once")
        print("PASS: old empty selection: preserved, schema migrated once")

        let legacy = CountingDefaults(values: [selectionKey: "\(CleanupCategory.userCaches.rawValue),obsoleteCategory"])
        let expectedMigration: Set<String> = [
            CleanupCategory.userCaches.rawValue,
            CleanupCategory.staleCodexRuntimeInstallers.rawValue
        ]
        for _ in 0..<100 {
            expect(CleanMacScanPreferences.selectedAreaIDs(defaults: legacy) == expectedMigration,
                   "Legacy migration must retain valid choices, discard obsolete IDs, and add stale runtimes")
        }
        expect(legacy.writtenKeys == [selectionKey, schemaKey], "Legacy selection must migrate exactly once")
        print("PASS: nonempty legacy selection: migrated once without losing valid choices")

        let futureSchema = CountingDefaults(values: [schemaKey: 2])
        _ = CleanMacScanPreferences.selectedAreaIDs(defaults: futureSchema)
        expect(futureSchema.writtenKeys.isEmpty, "An older app must not downgrade a future schema")
        print("PASS: future schema: preserved without writes")

        print("All 6 preference regression checks passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            FileHandle.standardError.write(Data("FAIL: \(message)\n".utf8))
            exit(1)
        }
    }
}
