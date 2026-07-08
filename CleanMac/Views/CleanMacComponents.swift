import SwiftUI

struct PageContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .padding(28)
                .frame(maxWidth: 1040, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

struct InfoPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.separator.opacity(0.6))
            }
    }
}

struct RiskBadge: View {
    let risk: CleanupRisk

    var body: some View {
        Label(risk.title, systemImage: risk == .safe ? "checkmark.shield" : "exclamationmark.triangle")
            .font(.caption.weight(.medium))
            .foregroundStyle(risk == .safe ? .green : .orange)
    }
}
