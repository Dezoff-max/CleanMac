import SwiftUI

enum CleanMacMotion {
    static func feedback(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.16)
    }

    static func progress(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.24)
    }
}

struct CleanMacMotionPhase {
    let isEnabled: Bool
    let isAnimating: Bool
}

/// Owns decorative loops so an inactive scene or Reduce Motion actually removes
/// their animated render tree. Progress values remain owned by the caller.
struct CleanMacContinuousMotion<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @ViewBuilder let content: (CleanMacMotionPhase) -> Content

    private var isEnabled: Bool {
        !reduceMotion && scenePhase == .active
    }

    var body: some View {
        CleanMacContinuousMotionContent(isEnabled: isEnabled, content: content)
            .id(isEnabled)
    }
}

private struct CleanMacContinuousMotionContent<Content: View>: View {
    let isEnabled: Bool
    let content: (CleanMacMotionPhase) -> Content

    @State private var isAnimating = false

    var body: some View {
        content(CleanMacMotionPhase(isEnabled: isEnabled, isAnimating: isAnimating))
            .transaction { transaction in
                if !isEnabled {
                    transaction.animation = nil
                    transaction.disablesAnimations = true
                }
            }
            .task {
                guard isEnabled else { return }
                // Give the new subtree its initial pose before starting a loop.
                await Task.yield()
                guard !Task.isCancelled else { return }
                isAnimating = true
            }
            .onDisappear {
                var transaction = Transaction(animation: nil)
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isAnimating = false
                }
            }
    }
}
