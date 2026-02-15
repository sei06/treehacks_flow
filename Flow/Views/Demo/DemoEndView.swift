import SwiftUI

struct DemoEndView: View {
    var onReplay: () -> Void
    var onContinue: () -> Void

    @State private var showTitle = false
    @State private var showBody = false
    @State private var showTagline = false
    @State private var showCredits = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            AuraTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // "flow"
                    Text("flow")
                        .font(.sora(48, weight: .light))
                        .foregroundColor(AuraTheme.textPrimary)
                        .tracking(4.8)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)

                    // Body text
                    VStack(spacing: 6) {
                        Text("Same person.")
                        Text("Three different moments.")
                        Text("Three soundtracks that")
                        Text("never existed before.")
                    }
                    .font(.sora(20, weight: .light))
                    .foregroundColor(AuraTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(showBody ? 1 : 0)
                    .offset(y: showBody ? 0 : 20)

                    // Tagline
                    Text("Music that feels you.")
                        .font(.sora(15))
                        .foregroundColor(AuraTheme.accent)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 20)

                    // Credits
                    VStack(spacing: 2) {
                        Text("Meta Ray-Ban Glasses \u{00B7} Gemini \u{00B7} Suno AI")
                        Text("TreeHacks 2025")
                    }
                    .font(.mono(10))
                    .foregroundColor(AuraTheme.textTertiary)
                    .multilineTextAlignment(.center)
                    .opacity(showCredits ? 1 : 0)
                    .offset(y: showCredits ? 0 : 20)

                    // Continue button
                    Button(action: onContinue) {
                        Text("try it yourself")
                            .font(.sora(15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(AuraTheme.accent)
                            )
                    }
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 20)

                    // Replay button
                    Button(action: onReplay) {
                        Text("replay demo")
                            .font(.sora(13))
                            .foregroundColor(AuraTheme.accent)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(AuraTheme.accent.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(AuraTheme.accent.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .opacity(showButtons ? 1 : 0)
                    .offset(y: showButtons ? 0 : 20)
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
        .onAppear {
            startSequence()
        }
    }

    private func startSequence() {
        let ease = Animation.easeOut(duration: 0.8)

        withAnimation(ease.delay(0.3)) { showTitle = true }
        withAnimation(ease.delay(1.2)) { showBody = true }
        withAnimation(ease.delay(3.0)) { showTagline = true }
        withAnimation(ease.delay(4.5)) { showCredits = true }
        withAnimation(ease.delay(6.0)) { showButtons = true }
    }
}
