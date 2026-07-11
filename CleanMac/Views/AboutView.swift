import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(CleanMacLanguage.storageKey) private var languageCode = CleanMacLanguage.defaultCode

    private let repositoryURL = URL(string: "https://github.com/Dezoff-max/CleanMac")!
    private let releasesURL = URL(string: "https://github.com/Dezoff-max/CleanMac/releases")!
    private let licenseURL = URL(string: "https://github.com/Dezoff-max/CleanMac/blob/main/LICENSE")!

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        ZStack {
            MainWindowBackground()

            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.1),
                    Color.clear,
                    Color(nsColor: .windowBackgroundColor).opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                Image("BrandIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 7)
                    .accessibilityLabel(L.t("app.name"))

                VStack(spacing: 5) {
                    Text(L.t("app.name"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))

                    Text(L.t("about.tagline"))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(L.f("about.version", version, build))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.11), in: Capsule())
                        .textSelection(.enabled)
                }

                VStack(spacing: 0) {
                    AboutRow(title: L.t("about.developer"), value: "@rootoff")
                    Divider()
                    AboutRow(title: L.t("about.dataMode"), value: L.t("about.dataMode.value"))
                    Divider()
                    AboutRow(title: L.t("about.cleanupMode"), value: L.t("about.cleanupMode.value"))
                    Divider()
                    AboutRow(title: L.t("about.license"), value: "MIT")
                }
                .background(
                    Color(nsColor: .controlBackgroundColor).opacity(0.9),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.separator.opacity(0.55))
                }

                HStack(spacing: 10) {
                    AboutLink(
                        title: L.t("about.github"),
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        destination: repositoryURL
                    )
                    AboutLink(
                        title: L.t("about.releases"),
                        systemImage: "arrow.down.circle",
                        destination: releasesURL
                    )
                    AboutLink(
                        title: L.t("about.license"),
                        systemImage: "doc.text",
                        destination: licenseURL
                    )
                }

                Text(L.t("about.safetyNote"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button(L.t("about.close")) {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 20)
        }
        .frame(width: 520, height: 500)
        .navigationTitle(L.t("about.windowTitle"))
        .id(languageCode)
    }
}

private struct AboutRow: View {
    let title: String
    let value: String

    var body: some View {
        LabeledContent {
            Text(value)
                .fontWeight(.semibold)
        } label: {
            Text(title)
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private struct AboutLink: View {
    let title: String
    let systemImage: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            Label(title, systemImage: systemImage)
                .frame(minWidth: 104)
        }
        .buttonStyle(.bordered)
    }
}
