import AppKit
import CleanMacCore
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
                    Text(CleanMacCoreInfo.status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open CleanMac", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
}
