import AppKit
import SwiftUI

struct SidebarView: View {
    @Binding var selection: String?
    @AppStorage(CleanMacLanguage.storageKey) private var languageCode = CleanMacLanguage.defaultCode
    @AppStorage(CleanMacAppearance.storageKey) private var appearanceMode = CleanMacAppearance.defaultCode

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(CleanMacSection.allCases) { section in
                        SidebarSectionButton(
                            section: section,
                            isSelected: selection == section.rawValue
                        ) {
                            selection = section.rawValue
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

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

private struct SidebarSectionButton: View {
    let section: CleanMacSection
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isKeyboardFocused: Bool
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                sectionIcon
                    .frame(width: 18, height: 18)
                    .scaleEffect(iconScale)

                Text(section.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(titleColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.88)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: 32)
            .background(rowBackground)
            .overlay(rowBorder)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .offset(x: rowOffset)
            .scaleEffect(rowScale, anchor: .leading)
            .shadow(color: shadowColor, radius: shadowRadius, y: 2)
        }
        .buttonStyle(SidebarPressButtonStyle())
        .focusable(true)
        .focused($isKeyboardFocused)
        .help(section.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .onHover { hovering in
            withAnimation(rowAnimation) {
                isHovered = hovering
            }
        }
        .animation(rowAnimation, value: isSelected)
        .animation(rowAnimation, value: isHovered)
        .animation(rowAnimation, value: isKeyboardFocused)
    }

    @ViewBuilder
    private var sectionIcon: some View {
        if section == .applications {
            Image(nsImage: SidebarApplicationIcon.image)
                .resizable()
                .renderingMode(.template)
                .interpolation(.high)
                .antialiased(true)
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(iconColor)
                .padding(0.25)
        } else {
            Image(systemName: section.systemImage)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(iconColor)
        }
    }

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(backgroundColor)
            .overlay {
                if isSelected && isHovered {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
            }
    }

    private var rowBorder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(borderColor, lineWidth: borderWidth)
    }

    private var backgroundColor: Color {
        if isSelected {
            return .accentColor
        }

        if isKeyboardFocused {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.12)
        }

        if isHovered {
            return Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.07)
        }

        return .clear
    }

    private var borderColor: Color {
        if isKeyboardFocused {
            return isSelected ? Color.white.opacity(0.78) : .accentColor
        }

        return isHovered && !isSelected ? Color.primary.opacity(colorScheme == .dark ? 0.13 : 0.08) : .clear
    }

    private var borderWidth: CGFloat {
        if isKeyboardFocused {
            return isSelected ? 1 : 1.4
        }

        return isHovered && !isSelected ? 1 : 0
    }

    private var iconColor: Color {
        if isSelected {
            return .white
        }

        return isHovered || isKeyboardFocused ? .accentColor : .primary
    }

    private var titleColor: Color {
        isSelected ? .white : .primary
    }

    private var rowOffset: CGFloat {
        isHovered && !isSelected && !reduceMotion ? 3 : 0
    }

    private var rowScale: CGFloat {
        isHovered && !isSelected && !reduceMotion ? 1.015 : 1
    }

    private var iconScale: CGFloat {
        (isHovered || isKeyboardFocused) && !reduceMotion ? 1.08 : 1
    }

    private var shadowColor: Color {
        if isKeyboardFocused {
            return Color.accentColor.opacity(colorScheme == .dark ? 0.32 : 0.22)
        }

        return isHovered && !isSelected ? Color.black.opacity(colorScheme == .dark ? 0.18 : 0.08) : .clear
    }

    private var shadowRadius: CGFloat {
        if isKeyboardFocused {
            return 8
        }

        return isHovered && !isSelected ? 6 : 0
    }

    private var rowAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.16)
    }
}

private enum SidebarApplicationIcon {
    static let image: NSImage = {
        let resourcePath = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/SidebarApplicationsFolder.icns"
        if let source = NSImage(contentsOfFile: resourcePath),
           let bitmap = source.representations
            .compactMap({ $0 as? NSBitmapImageRep })
            .first(where: { $0.pixelsWide == 36 && $0.pixelsHigh == 36 }),
           let cgImage = bitmap.cgImage {
            let image = NSImage(
                cgImage: cgImage,
                size: NSSize(width: 18, height: 18)
            )
            image.isTemplate = true
            return image
        }

        return NSImage(
            systemSymbolName: "square.stack.3d.up.fill",
            accessibilityDescription: L.t("section.applications")
        ) ?? NSImage(size: NSSize(width: 18, height: 18))
    }()
}

private struct SidebarPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.972 : 1)
            .brightness(configuration.isPressed && !reduceMotion ? -0.025 : 0)
            .animation(
                reduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.72),
                value: configuration.isPressed
            )
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
