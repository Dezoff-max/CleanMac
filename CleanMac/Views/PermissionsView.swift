import AppKit
import SwiftUI

struct PermissionsView: View {
    @State private var fullDiskAccess = FullDiskAccessChecker().check()

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: L.t("permissions.title"),
                    subtitle: L.t("permissions.subtitle"),
                    systemImage: "lock.shield"
                )

                VStack(spacing: 10) {
                    ForEach(CleanMacCatalog.permissions(fullDiskAccess: fullDiskAccess)) { permission in
                        PermissionRow(permission: permission)
                    }
                }

                HStack {
                    Spacer()

                    Button {
                        refreshFullDiskAccess()
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
        }
    }

    private func refreshFullDiskAccess() {
        fullDiskAccess = FullDiskAccessChecker().check()
    }

    private func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

private struct PermissionRow: View {
    let permission: PermissionItem

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
                }

                Spacer()

                Text(permission.state.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(permission.state.foregroundStyle)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(permission.state.backgroundStyle, in: Capsule())
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
        case .later: .secondary
        }
    }

    var backgroundStyle: Color {
        switch self {
        case .granted: .green.opacity(0.12)
        case .limited: .orange.opacity(0.14)
        case .unknown: .secondary.opacity(0.12)
        case .recommended: .blue.opacity(0.12)
        case .later: .secondary.opacity(0.12)
        }
    }
}
