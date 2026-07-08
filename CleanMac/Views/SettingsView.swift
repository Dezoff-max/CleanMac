import SwiftUI

struct SettingsView: View {
    @Binding var safeModeEnabled: Bool
    @Binding var confirmBeforeCleanup: Bool
    @Binding var showMenuBarStatus: Bool

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
                    }
                }
            }
        }
    }
}
