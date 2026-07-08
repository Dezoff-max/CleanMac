import SwiftUI

struct SettingsView: View {
    @Binding var safeModeEnabled: Bool
    @Binding var confirmBeforeCleanup: Bool
    @Binding var showMenuBarStatus: Bool

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 20) {
                PageHeader(
                    title: "Settings",
                    subtitle: "Cleanup behavior and app controls",
                    systemImage: "gearshape"
                )

                InfoPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $safeModeEnabled) {
                            Label("Safe Mode", systemImage: "shield")
                        }

                        Divider()

                        Toggle(isOn: $confirmBeforeCleanup) {
                            Label("Confirm Before Cleanup", systemImage: "checkmark.seal")
                        }

                        Divider()

                        Toggle(isOn: $showMenuBarStatus) {
                            Label("Show Menu Bar Status", systemImage: "menubar.rectangle")
                        }
                    }
                }
            }
        }
    }
}
