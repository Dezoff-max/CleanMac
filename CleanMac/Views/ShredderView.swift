import CleanMacCore
import SwiftUI

struct ShredderView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var candidates: [SecureDeletionCandidate] = []
    @State private var isChoosingFiles = false
    @State private var isShredding = false
    @State private var completedCount = 0
    @State private var statusMessage: String?
    @State private var problemMessage: String?
    @State private var showingConfirmation = false
    @State private var confirmationText = ""
    @State private var acknowledgedLimitations = false

    private var palette: NeoShredderPalette {
        NeoShredderPalette(colorScheme: colorScheme)
    }

    private var totalSizeBytes: Int64 {
        candidates.reduce(0) { $0 + $1.sizeBytes }
    }

    private var confirmationPhrase: String {
        L.t("shredder.confirm.phrase")
    }

    private var isConfirmationValid: Bool {
        acknowledgedLimitations && confirmationText == confirmationPhrase
    }

    var body: some View {
        PageContainer {
            VStack(alignment: .leading, spacing: 16) {
                hackerHeader
                limitationPanel
                queueControls
                queuePanel

                if let statusMessage {
                    feedbackPanel(message: statusMessage, isProblem: false)
                }

                if let problemMessage {
                    feedbackPanel(message: problemMessage, isProblem: true)
                }
            }
        }
        .sheet(isPresented: $showingConfirmation) {
            confirmationSheet
        }
        .onChange(of: showingConfirmation) { _, isPresented in
            if isPresented {
                confirmationText = ""
                acknowledgedLimitations = false
            }
        }
    }

    private var hackerHeader: some View {
        NeoShredderPanel(palette: palette, isGlowing: true) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    terminalMark
                    headerCopy
                    Spacer(minLength: 12)
                    stateStack
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 14) {
                        terminalMark
                        headerCopy
                    }
                    stateStack
                }
            }
        }
    }

    private var terminalMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(palette.inset)
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(palette.cyan.opacity(0.5))
                }
                .shadow(color: palette.glow.opacity(0.8), radius: 16)

            Image(systemName: "terminal.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(palette.cyan)
        }
        .frame(width: 58, height: 58)
        .accessibilityHidden(true)
    }

    private var headerCopy: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(L.t("shredder.header.code"))
                .font(.caption.monospaced().weight(.bold))
                .tracking(1.2)
                .foregroundStyle(palette.cyan)

            Text(L.t("shredder.title"))
                .font(.largeTitle.monospaced().bold())
                .foregroundStyle(palette.textPrimary)

            Text(L.t("shredder.subtitle"))
                .foregroundStyle(palette.textMuted)
        }
    }

    private var stateStack: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack(spacing: 7) {
                stateChip(L.t("shredder.state.local"), color: palette.cyan)
                stateChip(L.t("shredder.state.noTrash"), color: palette.danger)
                stateChip(L.t("shredder.state.failClosed"), color: palette.success)
            }

            Text(L.f("shredder.queue.summary", candidates.count, CleanMacFormatters.bytes(totalSizeBytes)))
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(palette.textMuted)
        }
    }

    private func stateChip(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(color.opacity(0.1), in: Capsule())
            .overlay {
                Capsule().strokeBorder(color.opacity(0.35))
            }
    }

    private var limitationPanel: some View {
        NeoShredderPanel(palette: palette, tone: .warning) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title2)
                    .foregroundStyle(palette.danger)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L.t("shredder.warning.title"))
                        .font(.headline.monospaced())
                        .foregroundStyle(palette.textPrimary)

                    Text(L.t("shredder.warning.direct"))
                        .foregroundStyle(palette.textPrimary)

                    Text(L.t("shredder.warning.ssd"))
                        .font(.callout)
                        .foregroundStyle(palette.textMuted)
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var queueControls: some View {
        NeoShredderPanel(palette: palette) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    queueDescription
                    Spacer(minLength: 12)
                    actionButtons
                }

                VStack(alignment: .leading, spacing: 12) {
                    queueDescription
                    actionButtons
                }
            }
        }
    }

    private var queueDescription: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L.t("shredder.queue.title"))
                .font(.headline.monospaced())
                .foregroundStyle(palette.textPrimary)
            Text(L.t("shredder.queue.detail"))
                .font(.callout)
                .foregroundStyle(palette.textMuted)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                chooseFiles()
            } label: {
                Label(L.t("shredder.add"), systemImage: "plus.rectangle.on.folder")
            }
            .buttonStyle(NeoShredderButtonStyle(palette: palette))
            .disabled(isChoosingFiles || isShredding)

            Button {
                showingConfirmation = true
            } label: {
                if isShredding {
                    Label(
                        L.f("shredder.progress", completedCount, candidates.count),
                        systemImage: "hourglass"
                    )
                } else {
                    Label(L.t("shredder.execute"), systemImage: "bolt.shield.fill")
                }
            }
            .buttonStyle(NeoShredderButtonStyle(palette: palette, isDanger: true))
            .disabled(candidates.isEmpty || isShredding || isChoosingFiles)
        }
    }

    private var queuePanel: some View {
        NeoShredderPanel(palette: palette, isGlowing: !candidates.isEmpty) {
            if candidates.isEmpty {
                ContentUnavailableView(
                    L.t("shredder.empty.title"),
                    systemImage: "doc.badge.plus",
                    description: Text(L.t("shredder.empty.message"))
                )
                .foregroundStyle(palette.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(spacing: 0) {
                    ForEach(candidates) { candidate in
                        candidateRow(candidate)

                        if candidate.id != candidates.last?.id {
                            Divider().overlay(palette.line)
                        }
                    }
                }
            }
        }
    }

    private func candidateRow(_ candidate: SecureDeletionCandidate) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .font(.title3)
                .foregroundStyle(candidate.isAPFS ? palette.danger : palette.cyan)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(candidate.name)
                        .font(.headline.monospaced())
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)

                    Text(candidate.isAPFS ? L.t("shredder.file.bestEffort") : L.t("shredder.file.overwrite"))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(candidate.isAPFS ? palette.danger : palette.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            (candidate.isAPFS ? palette.danger : palette.cyan).opacity(0.1),
                            in: Capsule()
                        )
                }

                Text(candidate.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(palette.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(L.f(
                    "shredder.file.metadata",
                    CleanMacFormatters.bytes(candidate.sizeBytes),
                    candidate.fileSystemName
                ))
                .font(.caption2.monospaced())
                .foregroundStyle(palette.textMuted)
            }

            Spacer(minLength: 8)

            Button {
                candidates.removeAll { $0.id == candidate.id }
                statusMessage = nil
                problemMessage = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(palette.textMuted)
            .help(L.t("shredder.remove"))
            .disabled(isShredding)
        }
        .padding(.vertical, 10)
    }

    private func feedbackPanel(message: String, isProblem: Bool) -> some View {
        NeoShredderPanel(palette: palette, tone: isProblem ? .warning : .success) {
            Label(
                message,
                systemImage: isProblem ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
            )
            .foregroundStyle(isProblem ? palette.danger : palette.success)
        }
    }

    private var confirmationSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(palette.danger)
                    .shadow(color: palette.danger.opacity(0.45), radius: 12)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L.t("shredder.confirm.title"))
                        .font(.title2.monospaced().bold())
                    Text(L.f(
                        "shredder.confirm.summary",
                        candidates.count,
                        CleanMacFormatters.bytes(totalSizeBytes)
                    ))
                    .foregroundStyle(.secondary)
                }
            }

            Text(L.t("shredder.confirm.warning"))
                .fixedSize(horizontal: false, vertical: true)

            Toggle(isOn: $acknowledgedLimitations) {
                Text(L.t("shredder.confirm.acknowledge"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(L.f("shredder.confirm.type", confirmationPhrase))
                    .font(.callout.weight(.semibold))

                TextField(confirmationPhrase, text: $confirmationText)
                    .textFieldStyle(.roundedBorder)
                    .font(.body.monospaced())
            }

            HStack {
                Button(L.t("button.cancel")) {
                    showingConfirmation = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(L.t("shredder.confirm.action"), role: .destructive) {
                    showingConfirmation = false
                    executeShredder()
                }
                .disabled(!isConfirmationValid)
            }
        }
        .padding(24)
        .frame(width: 560)
    }

    private func chooseFiles() {
        guard !isChoosingFiles, !isShredding else { return }
        isChoosingFiles = true
        statusMessage = nil
        problemMessage = nil

        Task { @MainActor in
            await Task.yield()
            let urls = ShredderWorkspaceService.chooseFiles()
            var acceptedCount = 0
            var rejectionMessages: [String] = []
            let inspector = SecureFileShredder()

            for url in urls {
                do {
                    let candidate = try inspector.inspect(url: url)
                    guard !candidates.contains(where: { $0.id == candidate.id }) else {
                        continue
                    }
                    candidates.append(candidate)
                    acceptedCount += 1
                } catch {
                    rejectionMessages.append(L.f(
                        "shredder.error.file",
                        url.lastPathComponent,
                        errorReason(error)
                    ))
                }
            }

            isChoosingFiles = false
            if acceptedCount > 0 {
                statusMessage = L.f("shredder.status.added", acceptedCount)
            }
            if !rejectionMessages.isEmpty {
                problemMessage = rejectionMessages.prefix(3).joined(separator: "\n")
            }
        }
    }

    private func executeShredder() {
        guard !candidates.isEmpty, !isShredding else { return }
        let reviewedCandidates = candidates
        isShredding = true
        completedCount = 0
        statusMessage = nil
        problemMessage = nil

        Task {
            var removedBytes: Int64 = 0
            var removedIDs = Set<String>()
            var failures: [String] = []

            for candidate in reviewedCandidates {
                do {
                    let bytes = try await Task.detached(priority: .utility) {
                        try SecureFileShredder().shred(candidate)
                    }.value
                    removedBytes += bytes
                    removedIDs.insert(candidate.id)
                } catch {
                    failures.append(L.f(
                        "shredder.error.file",
                        candidate.name,
                        errorReason(error)
                    ))
                }
                completedCount += 1
            }

            candidates.removeAll { removedIDs.contains($0.id) }
            isShredding = false
            statusMessage = L.f(
                "shredder.status.complete",
                removedIDs.count,
                CleanMacFormatters.bytes(removedBytes)
            )
            if !failures.isEmpty {
                problemMessage = failures.prefix(3).joined(separator: "\n")
            }
        }
    }

    private func errorReason(_ error: Error) -> String {
        guard let error = error as? SecureDeletionError else {
            return L.t("shredder.error.generic")
        }

        switch error {
        case .pathUnavailable:
            return L.t("shredder.error.unavailable")
        case .protectedPath:
            return L.t("shredder.error.protected")
        case .packageContent:
            return L.t("shredder.error.package")
        case .symbolicLink:
            return L.t("shredder.error.symlink")
        case .notRegularFile:
            return L.t("shredder.error.regularOnly")
        case .multipleHardLinks:
            return L.t("shredder.error.hardLink")
        case .fileChanged:
            return L.t("shredder.error.changed")
        case .fileBusy:
            return L.t("shredder.error.busy")
        case .openFailed, .writeFailed, .syncFailed, .truncateFailed, .removeFailed:
            return L.t("shredder.error.io")
        }
    }
}

private enum NeoShredderTone {
    case normal
    case warning
    case success
}

private struct NeoShredderPanel<Content: View>: View {
    let palette: NeoShredderPalette
    var tone: NeoShredderTone = .normal
    var isGlowing = false
    let content: Content

    init(
        palette: NeoShredderPalette,
        tone: NeoShredderTone = .normal,
        isGlowing: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.tone = tone
        self.isGlowing = isGlowing
        self.content = content()
    }

    private var borderColor: Color {
        switch tone {
        case .normal: isGlowing ? palette.cyan.opacity(0.45) : palette.line
        case .warning: palette.danger.opacity(0.45)
        case .success: palette.success.opacity(0.4)
        }
    }

    private var shadowColor: Color {
        switch tone {
        case .normal: isGlowing ? palette.glow : .clear
        case .warning: palette.danger.opacity(0.18)
        case .success: palette.success.opacity(0.16)
        }
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(borderColor)
            }
            .shadow(color: palette.shadow, radius: 18, y: 10)
            .shadow(color: shadowColor, radius: isGlowing ? 20 : 12)
    }
}

private struct NeoShredderButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    let palette: NeoShredderPalette
    var isDanger = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(isDanger ? Color.white : palette.textPrimary)
            .padding(.horizontal, 13)
            .frame(minHeight: 34)
            .background(
                isDanger ? palette.danger : palette.inset,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder((isDanger ? palette.danger : palette.cyan).opacity(0.55))
            }
            .shadow(
                color: isEnabled ? (isDanger ? palette.danger : palette.glow).opacity(0.55) : .clear,
                radius: configuration.isPressed ? 6 : 12
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.45)
    }
}

private struct NeoShredderPalette {
    let surface: Color
    let inset: Color
    let textPrimary: Color
    let textMuted: Color
    let line: Color
    let cyan: Color
    let glow: Color
    let danger: Color
    let success: Color
    let shadow: Color

    init(colorScheme: ColorScheme) {
        if colorScheme == .dark {
            surface = Color(red: 0.125, green: 0.165, blue: 0.224)
            inset = Color(red: 0.086, green: 0.122, blue: 0.176)
            textPrimary = Color(red: 0.941, green: 0.961, blue: 1)
            textMuted = Color(red: 0.576, green: 0.635, blue: 0.729)
            line = Color.white.opacity(0.12)
            cyan = Color(red: 0.439, green: 0.914, blue: 1)
            glow = Color(red: 0.286, green: 0.643, blue: 1).opacity(0.42)
            danger = Color(red: 1, green: 0.498, blue: 0.573)
            success = Color(red: 0.259, green: 0.851, blue: 0.58)
            shadow = Color.black.opacity(0.48)
        } else {
            surface = Color(red: 0.965, green: 0.973, blue: 0.984)
            inset = Color(red: 0.89, green: 0.91, blue: 0.941)
            textPrimary = Color(red: 0.122, green: 0.145, blue: 0.208)
            textMuted = Color(red: 0.471, green: 0.514, blue: 0.596)
            line = Color(red: 0.52, green: 0.58, blue: 0.67).opacity(0.2)
            cyan = Color(red: 0.176, green: 0.49, blue: 0.984)
            glow = Color(red: 0.247, green: 0.573, blue: 1).opacity(0.34)
            danger = Color(red: 0.92, green: 0.22, blue: 0.31)
            success = Color(red: 0.12, green: 0.66, blue: 0.4)
            shadow = Color(red: 0.64, green: 0.69, blue: 0.78).opacity(0.28)
        }
    }
}
