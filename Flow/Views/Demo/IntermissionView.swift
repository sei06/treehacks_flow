import SwiftUI

struct IntermissionView: View {
    let scenario: DemoScenario
    let momentLabel: String
    let scenarioIndex: Int
    var onComplete: () -> Void

    @State private var showMoment = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            AuraTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                DemoProgressDots(activeIndex: scenarioIndex)
                    .padding(.top, 60)
                    .opacity(fadeOut ? 0 : 1)

                Spacer()

                VStack(spacing: 20) {
                    // "MOMENT ONE"
                    Text(momentLabel)
                        .font(.monoMedium(11))
                        .foregroundColor(scenario.stressColor)
                        .tracking(1.5)
                        .opacity(showMoment ? 1 : 0)
                        .offset(y: showMoment ? 0 : 20)

                    // Title
                    Text(scenario.title)
                        .font(.sora(32, weight: .light))
                        .foregroundColor(AuraTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)

                    // Subtitle
                    Text(scenario.subtitle)
                        .font(.sora(16, weight: .light))
                        .foregroundColor(AuraTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 310)
                        .opacity(showSubtitle ? 1 : 0)
                        .offset(y: showSubtitle ? 0 : 20)
                }
                .padding(.horizontal, 32)
                .opacity(fadeOut ? 0 : 1)

                Spacer()
            }
        }
        .onAppear {
            startSequence()
        }
    }

    private func startSequence() {
        let ease = Animation.easeOut(duration: 0.8)

        withAnimation(ease.delay(0.2)) { showMoment = true }
        withAnimation(ease.delay(0.6)) { showTitle = true }
        withAnimation(ease.delay(1.8)) { showSubtitle = true }

        // Begin fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeInOut(duration: 1.4)) {
                fadeOut = true
            }
        }

        // Auto-advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            onComplete()
        }
    }
}
