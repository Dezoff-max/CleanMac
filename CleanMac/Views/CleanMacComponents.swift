import AppKit
import SwiftUI

struct MainWindowBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Image("MainWindowBackground")
                .resizable()
                .scaledToFill()
                .opacity(colorScheme == .dark ? 0.3 : 0.72)

            Color(nsColor: .windowBackgroundColor)
                .opacity(colorScheme == .dark ? 0.72 : 0.42)

            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(colorScheme == .dark ? 0.34 : 0.58),
                    Color(nsColor: .windowBackgroundColor).opacity(colorScheme == .dark ? 0.54 : 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }
}

struct PageContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .padding(.horizontal, 28)
                .padding(.vertical, 20)
                .frame(maxWidth: 1080, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MainWindowBackground())
    }
}

struct PageHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let imageAssetName: String?

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        imageAssetName: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.imageAssetName = imageAssetName
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            headerIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var headerIcon: some View {
        if let imageAssetName {
            Image(imageAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 46, height: 46)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Image(systemName: systemImage)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .symbolRenderingMode(.hierarchical)
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
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.separator.opacity(0.6))
            }
    }
}

struct StatusBanner: View {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(tint.opacity(0.24))
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
