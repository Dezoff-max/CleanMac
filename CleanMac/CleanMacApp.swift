import AppKit
import SwiftUI
import CleanMacCore

@main
struct CleanMacApp: App {
    var body: some Scene {
        MenuBarExtra("CleanMac", image: "MenuBarIcon") {
            StatusMenuView()
        }
        .menuBarExtraStyle(.window)

        Window("CleanMac", id: "main") {
            HomeWindowView()
        }
        .defaultSize(width: 720, height: 480)
    }
}

private struct StatusMenuView: View {
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
                Label("Open", systemImage: "macwindow")
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

private struct HomeWindowView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            Text("CleanMac")
                .font(.largeTitle.bold())

            Text(CleanMacCoreInfo.status)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
