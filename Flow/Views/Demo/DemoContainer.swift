import SwiftUI

struct DemoContainer: View {
    @StateObject private var state = DemoState()
    var onDemoComplete: (() -> Void)? = nil

    var body: some View {
        ZStack {
            // Current screen
            Group {
                switch state.currentScreen {
                case .opening:
                    OpeningSequence(state: state) {
                        advanceToIntermission(index: 0)
                    }

                case .intermission:
                    IntermissionView(
                        scenario: state.currentScenario,
                        momentLabel: state.momentLabel,
                        scenarioIndex: state.scenarioIndex
                    ) {
                        advanceToScenario()
                    }
                    .id("intermission-\(state.scenarioIndex)")

                case .scenario:
                    ScenarioPlayerView(
                        scenario: state.currentScenario,
                        audioURL: state.currentTrackURL
                    ) {
                        advanceFromScenario()
                    }
                    .id("scenario-\(state.scenarioIndex)")

                case .orbTransition:
                    orbTransitionScreen

                case .end:
                    DemoEndView(onReplay: {
                        replay()
                    }, onContinue: {
                        onDemoComplete?()
                    })
                }
            }

            // Tap zones (Stories-style) — active on intermediate screens only
            if state.currentScreen != .opening && state.currentScreen != .end {
                tapZones
            }
        }
        .onAppear {
            Task {
                await state.generateAllTracks()
            }
        }
    }

    // MARK: - Orb Transition Screen

    private var orbTransitionScreen: some View {
        ZStack {
            AuraTheme.textPrimary.ignoresSafeArea()

            VStack(spacing: 12) {
                BreathingOrb(color: AuraTheme.accent, size: 56)
                    .allowsHitTesting(false)

                Text(state.scenarioIndex >= 2 ? "that's flow" : "next moment")
                    .font(.sora(12, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Tap Zones

    private var tapZones: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left 30% — go back
                Color.clear
                    .frame(width: geo.size.width * 0.3)
                    .contentShape(Rectangle())
                    .onTapGesture { goBack() }

                // Right 70% — go forward
                Color.clear
                    .frame(width: geo.size.width * 0.7)
                    .contentShape(Rectangle())
                    .onTapGesture { goForward() }
            }
        }
    }

    // MARK: - Navigation

    private func advanceToIntermission(index: Int) {
        withAnimation(.easeInOut(duration: 0.5)) {
            state.scenarioIndex = index
            state.currentScreen = .intermission
        }
    }

    private func advanceToScenario() {
        withAnimation(.easeInOut(duration: 0.3)) {
            state.currentScreen = .scenario
        }
    }

    private func advanceFromScenario() {
        withAnimation(.easeInOut(duration: 0.5)) {
            state.currentScreen = .orbTransition
        }
    }

    private func goForward() {
        switch state.currentScreen {
        case .opening:
            break // handled by OpeningSequence callback

        case .intermission:
            advanceToScenario()

        case .scenario:
            advanceFromScenario()

        case .orbTransition:
            if state.scenarioIndex < 2 {
                advanceToIntermission(index: state.scenarioIndex + 1)
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    state.currentScreen = .end
                }
            }

        case .end:
            onDemoComplete?()
        }
    }

    private func goBack() {
        switch state.currentScreen {
        case .opening:
            break

        case .intermission:
            if state.scenarioIndex > 0 {
                advanceToIntermission(index: state.scenarioIndex - 1)
            }

        case .scenario:
            withAnimation(.easeInOut(duration: 0.3)) {
                state.currentScreen = .intermission
            }

        case .orbTransition:
            withAnimation(.easeInOut(duration: 0.3)) {
                state.currentScreen = .scenario
            }

        case .end:
            withAnimation(.easeInOut(duration: 0.3)) {
                state.currentScreen = .orbTransition
                state.scenarioIndex = 2
            }
        }
    }

    private func replay() {
        state.reset()
        Task {
            await state.generateAllTracks()
        }
    }
}
