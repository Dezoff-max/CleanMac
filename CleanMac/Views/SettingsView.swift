import ServiceManagement
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
    @State private var isSendingTestNotification = false
    @State private var notificationTestResult: CleanMacNotificationDeliveryResult?

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

                Label(L.t("settings.general"), systemImage: "switch.2")
                    .font(.title3.bold())

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

                        LaunchAtLoginSettingsRow()

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

                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $autoScanNotificationsEnabled) {
                                    Label(L.t("settings.autoScanNotifications"), systemImage: "bell.badge")
                                }
                                .onChange(of: autoScanNotificationsEnabled) { _, isEnabled in
                                    notificationTestResult = nil

                                    guard isEnabled else {
                                        return
                                    }

                                    Task {
                                        _ = await CleanMacNotificationService.requestAuthorizationIfNeeded()
                                    }
                                }

                                HStack(spacing: 10) {
                                    Button {
                                        sendTestNotification()
                                    } label: {
                                        Label(L.t("settings.testNotification"), systemImage: "bell")
                                    }
                                    .disabled(isSendingTestNotification)

                                    if isSendingTestNotification {
                                        ProgressView()
                                            .controlSize(.small)
                                    }

                                    if let notificationTestResult {
                                        notificationStatusLabel(for: notificationTestResult)
                                    }
                                }
                            }
                        }
                    }
                }

                PermissionsSettingsSection()
            }
        }
    }

    private func sendTestNotification() {
        guard !isSendingTestNotification else {
            return
        }

        notificationTestResult = nil
        isSendingTestNotification = true

        Task {
            let result = await CleanMacNotificationService.sendTestNotification()
            await MainActor.run {
                notificationTestResult = result
                isSendingTestNotification = false
            }
        }
    }

    private func notificationStatusLabel(for result: CleanMacNotificationDeliveryResult) -> some View {
        Label {
            Text(notificationStatusText(for: result))
        } icon: {
            Image(systemName: notificationStatusIcon(for: result))
        }
        .font(.caption)
        .foregroundStyle(notificationStatusColor(for: result))
    }

    private func notificationStatusText(for result: CleanMacNotificationDeliveryResult) -> String {
        switch result {
        case .sent:
            return L.t("settings.testNotification.sent")
        case .disabled:
            return L.t("settings.testNotification.disabled")
        case .denied:
            return L.t("settings.testNotification.denied")
        case .failed:
            return L.t("settings.testNotification.failed")
        }
    }

    private func notificationStatusIcon(for result: CleanMacNotificationDeliveryResult) -> String {
        switch result {
        case .sent:
            return "checkmark.circle"
        case .disabled:
            return "bell.slash"
        case .denied:
            return "exclamationmark.triangle"
        case .failed:
            return "xmark.circle"
        }
    }

    private func notificationStatusColor(for result: CleanMacNotificationDeliveryResult) -> Color {
        switch result {
        case .sent:
            return .green
        case .disabled:
            return .secondary
        case .denied, .failed:
            return .orange
        }
    }
}

private struct LaunchAtLoginSettingsRow: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var manager = LaunchAtLoginManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: enabledBinding) {
                Label(L.t("settings.launchAtLogin"), systemImage: "person.crop.circle.badge.checkmark")
            }
            .disabled(manager.isBusy)

            HStack(spacing: 8) {
                Label(statusTitle, systemImage: statusIcon)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)

                if manager.isBusy {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()

                if shouldOfferSystemSettings {
                    Button(L.t("settings.launchAtLogin.openSystemSettings")) {
                        manager.openSystemSettings()
                    }
                    .controlSize(.small)
                }
            }

            Text(statusDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let failure = manager.lastFailure {
                Label(failureText(failure), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .task {
            manager.refresh(clearFailure: true)
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                return
            }
            manager.refresh(clearFailure: true)
        }
    }

    private var enabledBinding: Binding<Bool> {
        Binding {
            manager.isRequested
        } set: { enabled in
            Task {
                await manager.setEnabled(enabled)
            }
        }
    }

    private var shouldOfferSystemSettings: Bool {
        manager.status == .requiresApproval || manager.status == .notFound || manager.lastFailure != nil
    }

    private var statusTitle: String {
        switch manager.status {
        case .notRegistered:
            L.t("settings.launchAtLogin.status.disabled")
        case .enabled:
            L.t("settings.launchAtLogin.status.enabled")
        case .requiresApproval:
            L.t("settings.launchAtLogin.status.requiresApproval")
        case .notFound:
            L.t("settings.launchAtLogin.status.unavailable")
        @unknown default:
            L.t("settings.launchAtLogin.status.unavailable")
        }
    }

    private var statusDetail: String {
        switch manager.status {
        case .notRegistered:
            L.t("settings.launchAtLogin.detail.disabled")
        case .enabled:
            L.t("settings.launchAtLogin.detail.enabled")
        case .requiresApproval:
            L.t("settings.launchAtLogin.detail.requiresApproval")
        case .notFound:
            L.t("settings.launchAtLogin.detail.unavailable")
        @unknown default:
            L.t("settings.launchAtLogin.detail.unavailable")
        }
    }

    private var statusIcon: String {
        switch manager.status {
        case .enabled:
            "checkmark.circle.fill"
        case .requiresApproval:
            "exclamationmark.circle.fill"
        case .notFound:
            "xmark.circle.fill"
        case .notRegistered:
            "circle"
        @unknown default:
            "questionmark.circle"
        }
    }

    private var statusColor: Color {
        switch manager.status {
        case .enabled:
            .green
        case .requiresApproval:
            .orange
        case .notFound:
            .red
        case .notRegistered:
            .secondary
        @unknown default:
            .secondary
        }
    }

    private func failureText(_ failure: LaunchAtLoginManager.Failure) -> String {
        L.f(
            failure.enabling
                ? "settings.launchAtLogin.error.enable"
                : "settings.launchAtLogin.error.disable",
            failure.systemMessage
        )
    }
}
