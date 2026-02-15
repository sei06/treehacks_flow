import SwiftUI

struct NowPlayingCard: View {
    @ObservedObject var state: PipelineState
    var onNewMoment: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Album Art Zone
            ZStack(alignment: .bottom) {
                // Background gradient
                LinearGradient(
                    colors: [
                        AuraTheme.accent.opacity(0.2),
                        AuraTheme.accentMuted.opacity(0.1),
                        AuraTheme.well,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)

                // Album art or placeholder
                if let artURL = state.albumArtURL {
                    AsyncImage(url: artURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        placeholderArt
                    }
                    .frame(height: 200)
                    .clipped()
                } else {
                    placeholderArt
                }

                // Audio visualizer bars (top-right)
                if state.isPlaying {
                    VStack {
                        HStack {
                            Spacer()
                            AudioBars(color: AuraTheme.accent)
                                .padding(12)
                        }
                        Spacer()
                    }
                }

                // Gradient fade at bottom
                LinearGradient(
                    colors: [.clear, AuraTheme.surface],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
            }
            .frame(height: 200)
            .clipped()

            // Info Zone
            VStack(alignment: .leading, spacing: 0) {
                Text(state.trackTitle ?? "Composing...")
                    .font(.sora(22, weight: .light))
                    .foregroundColor(AuraTheme.textPrimary)
                    .padding(.bottom, 4)

                Text("Composed for you · just now")
                    .font(.sora(13, weight: .medium))
                    .foregroundColor(AuraTheme.accent)
                    .padding(.bottom, 14)

                // Metadata pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if let bpm = state.trackBPM {
                            MetadataPill(text: "\(bpm) BPM", color: AuraTheme.textTertiary)
                        }
                        if let mood = state.trackMood {
                            MetadataPill(text: mood.capitalized, color: AuraTheme.accent)
                        }
                        MetadataPill(text: "HR \(state.heartRate)", color: state.stressColor)
                        MetadataPill(text: "HRV \(state.hrv)ms", color: state.stressColor)
                    }
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 18)
        }
        .background(AuraTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
    }

    private var placeholderArt: some View {
        ZStack {
            LinearGradient(
                colors: [AuraTheme.accent.opacity(0.15), AuraTheme.well],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Text("🎵")
                .font(.system(size: 56))
                .opacity(0.15)
        }
        .frame(height: 200)
    }


}

// MARK: - Metadata Pill

private struct MetadataPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.mono(9))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(color.opacity(0.06))
            )
            .overlay(
                Capsule().stroke(color.opacity(0.09), lineWidth: 1)
            )
    }
}

// MARK: - Typing Indicator

private struct NewMomentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let color: Color
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1.0 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
