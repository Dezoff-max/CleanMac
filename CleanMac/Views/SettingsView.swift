import SwiftUI

struct SettingsView: View {
    @Binding var safeModeEnabled: Bool
    @Binding var confirmBeforeCleanup: Bool
    @Binding var showMenuBarStatus: Bool
    @AppStorage(CleanMacPreferenceKeys.autoScanEnabled) private var autoScanEnabled = false
    @AppStorage(CleanMacPreferenceKeys.autoScanHour) private var autoScanHour = CleanMacScanSchedule.defaultHour
    @AppStorage(CleanMacPreferenceKeys.autoScanMinute) private var autoScanMinute = CleanMacScanSchedule.defaultMinute
    @AppStorage(CleanMacPreferenceKeys.selectedAreaIDs) private var selectedAreaIDsRaw = CleanMacScanPreferences.defaultSelectedAreaIDsRaw

    private var selectedAreaCount: Int {
        guard !selectedAreaIDsRaw.isEmpty else {
            return 0
        }

        let validIDs = Set(CleanMacCatalog.cleanupAreas.map(\.id))
        let selectedIDs = Set(selectedAreaIDsRaw.split(separator: ",").map(String.init))
            .intersection(validIDs)
        return selectedIDs.isEmpty ? CleanMacScanPreferences.defaultSelectedAreaIDs.count : selectedIDs.count
    }

    private var autoScanTime: Binding<Date> {
        Binding {
            CleanMacScanSchedule.scheduledDate(on: Date())
        } set: { newValue in
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            autoScanHour = components.hour ?? CleanMacScanSchedule.defaultHour
            autoScanMinute = components.minute ?? CleanMacScanSchedule.defaultMinute
        }
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: L.t("settings.title"),
                    subtitle: L.t("settings.subtitle"),
                    systemImage: "gearshape"
                )

                InfoPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $safeModeEnabled) {
                            Label(L.t("settings.safeMode"), systemImage: "shield")
                        }

                        Divider()

                        Toggle(isOn: $confirmBeforeCleanup) {
                            Label(L.t("settings.confirmBeforeCleanup"), systemImage: "checkmark.seal")
                        }

                        Divider()

                        Toggle(isOn: $showMenuBarStatus) {
                            Label(L.t("settings.showMenuBarStatus"), systemImage: "menubar.rectangle")
                        }

                        Divider()

                        Toggle(isOn: $autoScanEnabled) {
                            Label(L.t("settings.autoScan"), systemImage: "clock.badge.checkmark")
                        }

                        if autoScanEnabled {
                            Divider()

                            DatePicker(
                                L.t("settings.autoScanTime"),
                                selection: autoScanTime,
                                displayedComponents: .hourAndMinute
                            )

                            Label(L.f("settings.autoScanAreas", selectedAreaCount), systemImage: "checklist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
