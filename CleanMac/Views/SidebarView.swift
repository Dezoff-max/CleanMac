import SwiftUI

struct SidebarView: View {
    @Binding var selection: String?

    var body: some View {
        List(CleanMacSection.allCases, selection: $selection) { section in
            Label(section.title, systemImage: section.systemImage)
                .tag(section.rawValue)
        }
        .listStyle(.sidebar)
        .navigationTitle(L.t("app.name"))
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        .onAppear {
            if selection == nil {
                selection = CleanMacSection.dashboard.rawValue
            }
        }
    }
}
