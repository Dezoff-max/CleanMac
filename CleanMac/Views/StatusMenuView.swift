import AppKit
import SwiftUI

struct StatusMenuView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(nsImage: NSImage(named: "MenuBarIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CleanMac")
                        .font(.headline)
                    Text(L.t("status.idle"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            Button {
                MainWindowController.show(openWindow: openWindow)
            } label: {
                Label(L.t("menu.open"), systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Label(L.t("menu.quit"), systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}
