import SwiftUI

struct OpeningSequence: View {
    @ObservedObject var state: DemoState
    var onComplete: () -> Void

    @State private var showTitle = false
    @State private var showLine1 = false
    @State private var showLine2 = false
    @State private var showBlock = false
    @State private var showTagline = false
    @State private var textDone = false

    var body: some View {
        ZStack {
            AuraTheme.bg.ignoresSafeArea()

            if textDone && !state.allTracksReady {
                // Waiting state
                VStack(spacing: 16) {
                    BreathingOrb(color: AuraTheme.accent, size: 120)
                        .allowsHitTesting(false)

                    Text("composing your soundtrack...")
                        .font(.sora(14, weight: .light))
                        .foregroundColor(AuraTheme.textTertiary)
                }
                .transition(.opacity)
            } else {
                // Text reveal sequence
                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 28) {
                        // "flow"
                        Text("flow")
                            .font(.sora(56, weight: .light))
                            .foregroundColor(AuraTheme.textPrimary)
                            .tracking(5.6)
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)

                        // "What if your music knew"
                        VStack(spacing: 4) {
                            Text("What if your music knew")
                                .opacity(showLine1 ? 1 : 0)
                                .offset(y: showLine1 ? 0 : 20)

                            Text("exactly how you feel?")
                                .opacity(showLine2 ? 1 : 0)
                                .offset(y: showLine2 ? 0 : 20)
                        }
                        .font(.sora(22, weight: .light))
                        .foregroundColor(AuraTheme.textSecondary)
                        .multilineTextAlignment(.center)

                        // 3-line block
                        Text("Flow reads your environment,\nsenses your stress through biometrics,\nand composes music in real time.")
                            .font(.sora(16, weight: .light))
                            .foregroundColor(AuraTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .opacity(showBlock ? 1 : 0)
                            .offset(y: showBlock ? 0 : 20)

                        // Tagline
                        Text("Three moments. Three soundtracks.\nSame person.")
                            .font(.sora(18))
                            .foregroundColor(AuraTheme.accent)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .opacity(showTagline ? 1 : 0)
                            .offset(y: showTagline ? 0 : 20)
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
        }
        .onAppear {
            startTextSequence()
        }
        .onChange(of: state.allTracksReady) { _, ready in
            if ready && textDone {
                onComplete()
            }
        }
    }

    private func startTextSequence() {
        let ease = Animation.easeOut(duration: 0.8)

        withAnimation(ease.delay(0.4)) { showTitle = true }
        withAnimation(ease.delay(2.5)) { showLine1 = true }
        withAnimation(ease.delay(3.2)) { showLine2 = true }
        withAnimation(ease.delay(5.5)) { showBlock = true }
        withAnimation(ease.delay(9.0)) { showTagline = true }

        // Text done at ~12s
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
            withAnimation(.easeInOut(duration: 0.5)) {
                textDone = true
            }
            if state.allTracksReady {
                onComplete()
            }
        }
    }
}
