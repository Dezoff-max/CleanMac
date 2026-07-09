import SwiftUI

struct SidebarView: View {
    @Binding var selection: String?
    @AppStorage(CleanMacLanguage.storageKey) private var languageCode = CleanMacLanguage.defaultCode
    @AppStorage(CleanMacAppearance.storageKey) private var appearanceMode = CleanMacAppearance.defaultCode

    var body: some View {
        VStack(spacing: 0) {
            List(CleanMacSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section.rawValue)
            }
            .listStyle(.sidebar)

            SidebarPreferenceSwitches(
                languageCode: $languageCode,
                appearanceMode: $appearanceMode
            )
        }
        .navigationTitle(L.t("app.name"))
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        .onAppear {
            if selection == nil {
                selection = CleanMacSection.dashboard.rawValue
            }
        }
    }
}

private struct SidebarPreferenceSwitches: View {
    @Binding var languageCode: String
    @Binding var appearanceMode: String

    var body: some View {
        VStack(spacing: 10) {
            Divider()

            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                Picker(L.t("sidebar.language"), selection: $languageCode) {
                    ForEach(CleanMacLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .help(L.t("sidebar.language"))
            }

            HStack(spacing: 8) {
                Image(systemName: CleanMacAppearance.value(for: appearanceMode) == .dark ? "moon.fill" : "sun.max.fill")
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                Picker(L.t("sidebar.appearance"), selection: $appearanceMode) {
                    Image(systemName: "sun.max.fill")
                        .tag(CleanMacAppearance.light.rawValue)
                        .accessibilityLabel(L.t("sidebar.appearance.light"))

                    Image(systemName: "moon.fill")
                        .tag(CleanMacAppearance.dark.rawValue)
                        .accessibilityLabel(L.t("sidebar.appearance.dark"))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .help(L.t("sidebar.appearance"))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }
}
