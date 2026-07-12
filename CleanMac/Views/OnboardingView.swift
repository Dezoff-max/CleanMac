import AppKit
import SwiftUI

struct OnboardingView: View {
    private enum Step: Int, CaseIterable {
        case welcome
        case capabilities
        case fullDiskAccess
        case ready
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step: Step = .welcome
    @State private var fullDiskAccess = FullDiskAccessChecker().check()

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            onboardingBackground

            VStack(spacing: 0) {
                topBar
                progressTrack

                GeometryReader { proxy in
                    ScrollView {
                        page
                            .frame(maxWidth: 820)
                            .frame(minHeight: max(500, proxy.size.height - 36))
                            .padding(.horizontal, 44)
                            .padding(.vertical, 18)
                            .frame(maxWidth: .infinity)
                    }
                }

                Divider()
                footer
            }
        }
        .frame(minWidth: 900, minHeight: 680)
        .background(WindowAccessor { window in
            MainWindowController.configure(window)
        })
        .onChange(of: step) { _, newStep in
            if newStep == .fullDiskAccess {
                fullDiskAccess = FullDiskAccessChecker().check()
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var onboardingBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            RadialGradient(
                colors: [
                    Color.accentColor.opacity(0.13),
                    Color.accentColor.opacity(0.035),
                    .clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 560
            )

            LinearGradient(
                colors: [
                    Color(nsColor: .controlBackgroundColor).opacity(0.34),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Image("BrandIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(L.t("onboarding.appTitle"))
                    .font(.headline)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .frame(width: 28, height: 28)
                    .background(.regularMaterial, in: Circle())
                    .overlay {
                        Circle().strokeBorder(.separator.opacity(0.55))
                    }
            }
            .buttonStyle(.plain)
            .help(L.t("onboarding.skip"))
            .accessibilityLabel(L.t("onboarding.skip"))
        }
        .padding(.horizontal, 22)
        .padding(.top, 14)
    }

    private var progressTrack: some View {
        HStack(spacing: 0) {
            ForEach(Array(Step.allCases.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Capsule()
                        .fill(index <= step.rawValue ? Color.accentColor : Color.secondary.opacity(0.22))
                        .frame(width: 46, height: 3)
                }

                ZStack {
                    Circle()
                        .fill(item.rawValue <= step.rawValue ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(width: 22, height: 22)

                    if item.rawValue < step.rawValue {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(item.rawValue + 1)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(item.rawValue == step.rawValue ? .white : .secondary)
                    }
                }
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L.f("onboarding.progress", step.rawValue + 1, Step.allCases.count))
    }

    @ViewBuilder
    private var page: some View {
        Group {
            switch step {
            case .welcome:
                welcomePage
            case .capabilities:
                capabilitiesPage
            case .fullDiskAccess:
                fullDiskAccessPage
            case .ready:
                readyPage
            }
        }
        .id(step)
        .transition(reduceMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 34)

            Image("BrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 132, height: 132)
                .shadow(color: Color.accentColor.opacity(0.22), radius: 24, y: 10)
                .accessibilityLabel(L.t("app.name"))

            VStack(spacing: 12) {
                Text(L.t("onboarding.welcome.title"))
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text(L.t("onboarding.welcome.subtitle"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 620)
                    .fixedSize(horizontal: false, vertical: true)
            }

            onboardingBadge(
                L.t("onboarding.welcome.badge"),
                systemImage: "checkmark.shield.fill",
                tint: .green
            )

            Spacer(minLength: 34)
        }
    }

    private var capabilitiesPage: some View {
        VStack(spacing: 22) {
            pageHeading(
                title: L.t("onboarding.capabilities.title"),
                subtitle: L.t("onboarding.capabilities.subtitle")
            )

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                spacing: 14
            ) {
                capabilityCard("cleanup", icon: "sparkles", tint: .blue)
                capabilityCard("disk", icon: "chart.pie.fill", tint: .purple)
                capabilityCard("apps", icon: "app.badge.checkmark", tint: .orange)
                capabilityCard("safe", icon: "checkmark.shield.fill", tint: .green)
                capabilityCard("schedule", icon: "clock.badge.checkmark", tint: .cyan)
                capabilityCard("local", icon: "externaldrive.fill.badge.checkmark", tint: .indigo)
            }
        }
        .padding(.top, 24)
    }

    private var fullDiskAccessPage: some View {
        VStack(spacing: 18) {
            heroSymbol("lock.shield.fill", tint: .blue)

            pageHeading(
                title: L.t("onboarding.access.title"),
                subtitle: L.t("onboarding.access.subtitle")
            )

            onboardingBadge(
                fullDiskAccess.state == .granted
                    ? L.t("onboarding.access.granted")
                    : L.t("onboarding.access.limited"),
                systemImage: fullDiskAccess.state == .granted ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                tint: fullDiskAccess.state == .granted ? .green : .orange
            )

            VStack(spacing: 0) {
                instructionRow(number: 1, text: L.t("onboarding.access.step1"))
                Divider().padding(.leading, 54)
                instructionRow(number: 2, text: L.t("onboarding.access.step2"))
                Divider().padding(.leading, 54)
                instructionRow(number: 3, text: L.t("onboarding.access.step3"))
                Divider().padding(.leading, 54)
                instructionRow(number: 4, text: L.t("onboarding.access.step4"))
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.separator.opacity(0.55))
            }

            Button {
                openFullDiskAccessSettings()
            } label: {
                Label(L.t("onboarding.access.openSettings"), systemImage: "gearshape")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Text(L.t("onboarding.access.optional"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    private var readyPage: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 50)

            ZStack {
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 116, height: 116)
                    .shadow(color: .green.opacity(0.24), radius: 24, y: 10)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 12) {
                Text(L.t("onboarding.ready.title"))
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text(L.t("onboarding.ready.subtitle"))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 650)
                    .fixedSize(horizontal: false, vertical: true)
            }

            onboardingBadge(
                L.t("onboarding.ready.badge"),
                systemImage: "trash.slash.fill",
                tint: .blue
            )

            Spacer(minLength: 50)
        }
    }

    private var footer: some View {
        HStack {
            Button(L.t("onboarding.back")) {
                move(to: max(0, step.rawValue - 1))
            }
            .controlSize(.large)
            .disabled(step == .welcome)
            .opacity(step == .welcome ? 0 : 1)

            Spacer()

            HStack(spacing: 7) {
                ForEach(Step.allCases, id: \.rawValue) { item in
                    Circle()
                        .fill(item == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: item == step ? 9 : 7, height: item == step ? 9 : 7)
                }
            }
            .accessibilityHidden(true)

            Spacer()

            Button(step == .ready ? L.t("onboarding.getStarted") : L.t("onboarding.next")) {
                if step == .ready {
                    onComplete()
                } else {
                    move(to: step.rawValue + 1)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(.bar)
    }

    private func pageHeading(title: String, subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 680)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func capabilityCard(_ key: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(L.t("onboarding.capability.\(key).title"))
                    .font(.headline)
                Text(L.t("onboarding.capability.\(key).detail"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.separator.opacity(0.5))
        }
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.gradient, in: Circle())

            Text(text)
                .font(.body.weight(.medium))

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func onboardingBadge(_ title: String, systemImage: String, tint: Color) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(tint.opacity(0.11), in: Capsule())
    }

    private func heroSymbol(_ name: String, tint: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 50, weight: .semibold))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(width: 92, height: 92)
            .background(tint.opacity(0.11), in: Circle())
    }

    private func move(to rawValue: Int) {
        guard let destination = Step(rawValue: rawValue) else {
            return
        }

        withAnimation(reduceMotion ? .easeOut(duration: 0.12) : .spring(response: 0.34, dampingFraction: 0.88)) {
            step = destination
        }
    }

    private func openFullDiskAccessSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
