import AppKit
import SwiftUI

struct PermissionsSettingsSection: View {
    @State private var fullDiskAccess = FullDiskAccessChecker().check()
    @State private var finderAutomationPermission: FinderAutomationPermission?
    @State private var isRequestingFinderAutomation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L.t("permissions.title"), systemImage: "lock.shield")
                .font(.title3.bold())

            Text(L.t("permissions.subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                ForEach(CleanMacCatalog.permissions(
                    fullDiskAccess: fullDiskAccess,
                    finderAutomationPermission: finderAutomationPermission
                )) { permission in
                    if permission.id == "automation" {
                        PermissionRow(
                            permission: permission,
                            actionTitle: automationActionTitle,
                            isActionInProgress: isRequestingFinderAutomation || finderAutomationPermission == nil,
                            action: handleAutomationAction
                        )
                    } else {
                        PermissionRow(permission: permission)
                    }
                }
            }

            HStack {
                Spacer()

                Button {
                    refreshAccess()
                } label: {
                    Label(L.t("button.refreshAccess"), systemImage: "arrow.clockwise")
                }

                Button {
                    openPrivacySettings()
                } label: {
                    Label(L.t("button.openSystemSettings"), systemImage: "gearshape")
                }
            }
        }
        .task {
            await refreshFinderAutomationPermission()
        }
    }

    private var automationActionTitle: String? {
        switch finderAutomationPermission {
        case .notDetermined:
            L.t("button.requestAutomation")
        case .denied:
            L.t("button.openAutomationSettings")
        default:
            nil
        }
    }

    private func refreshAccess() {
        fullDiskAccess = FullDiskAccessChecker().check()
        Task {
            await refreshFinderAutomationPermission()
        }
    }

    private func refreshFinderAutomationPermission() async {
        guard !isRequestingFinderAutomation else {
            return
        }

        finderAutomationPermission = nil
        finderAutomationPermission = await CleanMacAutomationService.checkFinderPermission()
    }

    private func handleAutomationAction() {
        switch finderAutomationPermission {
        case .notDetermined:
            requestFinderAutomationPermission()
        case .denied:
            openAutomationSettings()
        default:
            break
        }
    }

    private func requestFinderAutomationPermission() {
        guard !isRequestingFinderAutomation else {
            return
        }

        isRequestingFinderAutomation = true
        finderAutomationPermission = nil

        Task {
            finderAutomationPermission = await CleanMacAutomationService.requestFinderPermission()
            isRequestingFinderAutomation = false
        }
    }

    private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func openAutomationSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private struct PermissionRow: View {
    let permission: PermissionItem
    var actionTitle: String? = nil
    var isActionInProgress = false
    var action: (() -> Void)? = nil

    var body: some View {
        InfoPanel {
            HStack(spacing: 12) {
                Image(systemName: permission.systemImage)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 5) {
                    Text(permission.title)
                        .font(.headline)
                    Text(permission.detail)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(permission.state.title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(permission.state.foregroundStyle)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(permission.state.backgroundStyle, in: Capsule())

                    if isActionInProgress {
                        ProgressView()
                            .controlSize(.small)
                    } else if let actionTitle, let action {
                        Button(actionTitle, action: action)
                            .controlSize(.small)
                    }
                }
            }
        }
    }
}

private extension PermissionState {
    var foregroundStyle: Color {
        switch self {
        case .granted: .green
        case .limited: .orange
        case .unknown: .secondary
        case .recommended: .blue
        case .notRequested: .blue
        case .denied: .orange
        case .unavailable, .checking: .secondary
        }
    }

    var backgroundStyle: Color {
        switch self {
        case .granted: .green.opacity(0.12)
        case .limited: .orange.opacity(0.14)
        case .unknown: .secondary.opacity(0.12)
        case .recommended: .blue.opacity(0.12)
        case .notRequested: .blue.opacity(0.12)
        case .denied: .orange.opacity(0.14)
        case .unavailable, .checking: .secondary.opacity(0.12)
        }
    }
}
