import SwiftUI

struct SettingsView: View {
    @Binding var safeModeEnabled: Bool
    @Binding var confirmBeforeCleanup: Bool
    @Binding var showMenuBarStatus: Bool
    @AppStorage(CleanMacPreferenceKeys.autoScanEnabled) private var autoScanEnabled = false
    @AppStorage(CleanMacPreferenceKeys.autoScanFrequency) private var autoScanFrequency = CleanMacAutoScanFrequency.defaultFrequency.rawValue
    @AppStorage(CleanMacPreferenceKeys.autoScanHour) private var autoScanHour = CleanMacScanSchedule.defaultHour
    @AppStorage(CleanMacPreferenceKeys.autoScanMinute) private var autoScanMinute = CleanMacScanSchedule.defaultMinute
    @AppStorage(CleanMacPreferenceKeys.autoScanNotificationsEnabled) private var autoScanNotificationsEnabled = true
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

    private var autoScanFrequencyBinding: Binding<CleanMacAutoScanFrequency> {
        Binding {
            CleanMacAutoScanFrequency(rawValue: autoScanFrequency) ?? CleanMacAutoScanFrequency.defaultFrequency
        } set: { newValue in
            autoScanFrequency = newValue.rawValue
        }
    }

    private var selectedFrequency: CleanMacAutoScanFrequency {
        CleanMacAutoScanFrequency(rawValue: autoScanFrequency) ?? CleanMacAutoScanFrequency.defaultFrequency
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
                        .onChange(of: autoScanEnabled) { _, isEnabled in
                            guard isEnabled, autoScanNotificationsEnabled else {
                                return
                            }

                            Task {
                                _ = await CleanMacNotificationService.requestAuthorizationIfNeeded()
                            }
                        }

                        if autoScanEnabled {
                            Divider()

                            VStack(alignment: .leading, spacing: 8) {
                                Label(L.t("settings.autoScanFrequency"), systemImage: "repeat")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Picker(L.t("settings.autoScanFrequency"), selection: autoScanFrequencyBinding) {
                                    ForEach(CleanMacAutoScanFrequency.allCases) { frequency in
                                        Text(frequency.title).tag(frequency)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }

                            Divider()

                            DatePicker(
                                selectedFrequency == .daily ? L.t("settings.autoScanTime") : L.t("settings.autoScanStartTime"),
                                selection: autoScanTime,
                                displayedComponents: .hourAndMinute
                            )

                            Label(L.f("settings.autoScanAreas", selectedAreaCount), systemImage: "checklist")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider()

                            Toggle(isOn: $autoScanNotificationsEnabled) {
                                Label(L.t("settings.autoScanNotifications"), systemImage: "bell.badge")
                            }
                            .onChange(of: autoScanNotificationsEnabled) { _, isEnabled in
                                guard isEnabled else {
                                    return
                                }

                                Task {
                                    _ = await CleanMacNotificationService.requestAuthorizationIfNeeded()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
