import AppKit
import SwiftUI

struct PermissionsView: View {
    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "Permissions",
                    subtitle: "Control what CleanMac can inspect",
                    systemImage: "lock.shield"
                )

                VStack(spacing: 10) {
                    ForEach(CleanMacCatalog.permissions) { permission in
                        PermissionRow(permission: permission)
                    }
                }

                HStack {
                    Spacer()

                    Button {
                        openPrivacySettings()
                    } label: {
                        Label("Open System Settings", systemImage: "gearshape")
                    }
                }
            }
        }
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}
