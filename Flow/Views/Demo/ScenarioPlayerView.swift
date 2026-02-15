import AVFoundation
import SwiftUI

struct ScenarioPlayerView: View {
    let scenario: DemoScenario
    let audioURL: URL?
    var onComplete: () -> Void

    @State private var videoPlayer: AVPlayer?
    @State private var audioPlayer: AVPlayer?
    @State private var videoOpacity: Double = 1.0
    @State private var overlayOpacity: Double = 1.0
    @State private var playbackProgress: Double = 0.0
    @State private var fadeTimer: Timer?
    @State private var progressTimer: Timer?
    @State private var showOrb = false

    private let videoDuration: Double = 30.0

    var body: some View {
        ZStack {
            // Background (visible when video fades)
            AuraTheme.textPrimary.ignoresSafeArea()

            // Video layer
            if let player = videoPlayer {
                VideoPlayerLayer(player: player)
                    .ignoresSafeArea()
                    .opacity(videoOpacity)
            }

            // Overlays on video
            if !showOrb {
                overlays
                    .opacity(overlayOpacity)
            }

            // Orb screen (after fade)
            if showOrb {
                orbScreen
                    .transition(.opacity)
            }
        }
        .onAppear {
            startPlayback()
        }
        .onDisappear {
            cleanup()
        }
    }

    // MARK: - Overlays

    private var overlays: some View {
        ZStack {
            // Top-left: biometric pills
            VStack {
                HStack(spacing: 8) {
                    BiometricPill {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundColor(scenario.stressColor)
                            Text("\(scenario.hr)")
                                .font(.monoMedium(10))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    BiometricPill {
                        HStack(spacing: 4) {
                            Text("HRV")
                                .font(.monoMedium(8))
                                .foregroundColor(.white.opacity(0.5))
                            Text("\(scenario.hrv)")
                                .font(.monoMedium(10))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }

                    Spacer()

                    // Top-right: stress pill
                    BiometricPill {
                        HStack(spacing: 5) {
                            BreathingDot(color: scenario.stressColor)
                            Text(scenario.stressLabel)
                                .font(.monoMedium(10))
                                .foregroundColor(scenario.stressColor)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 54)

                Spacer()
            }

            // Bottom: now-playing bar over gradient scrim
            VStack {
                Spacer()

                ZStack(alignment: .bottom) {
                    // Gradient scrim — extends into safe area
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 240)

                    VStack(alignment: .leading, spacing: 8) {
                        // Track title + audio bars
                        HStack {
                            Text(scenario.trackTitle)
                                .font(.sora(18, weight: .light))
                                .foregroundColor(.white)

                            Spacer()

                            DemoAudioBars(color: .white.opacity(0.6))
                        }

                        Text("Composed for you")
                            .font(.sora(11))
                            .foregroundColor(.white.opacity(0.4))

                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 99)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 2)
                                RoundedRectangle(cornerRadius: 99)
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: max(0, geo.size.width * playbackProgress), height: 2)
                            }
                        }
                        .frame(height: 2)

                        // Metadata pills
                        HStack(spacing: 6) {
                            DemoMetaPill(text: "\(scenario.bpm) BPM")
                            DemoMetaPill(text: scenario.mood)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Orb Screen

    private var orbScreen: some View {
        ZStack {
            AuraTheme.textPrimary.ignoresSafeArea()

            VStack(spacing: 12) {
                BreathingOrb(color: AuraTheme.accent, size: 56)
                    .allowsHitTesting(false)

                Text("next moment")
                    .font(.sora(12, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Playback

    private func startPlayback() {
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        // Video
        if let videoURL = Bundle.main.url(forResource: scenario.videoFileName, withExtension: nil) {
            let player = AVPlayer(url: videoURL)
            videoPlayer = player
            player.play()
        }

        // Audio
        if let url = audioURL {
            let player = AVPlayer(url: url)
            audioPlayer = player
            player.volume = 1.0
            player.play()
        }

        // Progress timer
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                playbackProgress = min(playbackProgress + (0.1 / videoDuration), 1.0)
            }
        }

        // Start fade at 25s
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            startFade()
        }

        // Show orb at 30s
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            progressTimer?.invalidate()
            withAnimation(.easeInOut(duration: 0.5)) {
                showOrb = true
            }
        }

        // Auto-complete at 30.5s (user can also tap)
        DispatchQueue.main.asyncAfter(deadline: .now() + 32) {
            // Only auto-advance if tap hasn't already done it
        }
    }

    private func startFade() {
        // Manual volume stepping for audio fade
        var volume: Float = 1.0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            volume -= 0.02 // 1.0 to 0.0 over 5s (50 steps * 0.1s)
            if volume <= 0 {
                volume = 0
                timer.invalidate()
            }
            Task { @MainActor in
                audioPlayer?.volume = volume
            }
        }

        // Video + overlay fade
        withAnimation(.easeInOut(duration: 5.0)) {
            videoOpacity = 0
            overlayOpacity = 0
        }
    }

    private func cleanup() {
        fadeTimer?.invalidate()
        progressTimer?.invalidate()
        videoPlayer?.pause()
        videoPlayer = nil
        audioPlayer?.pause()
        audioPlayer = nil
    }
}

// MARK: - Video Player UIViewRepresentable

private struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private class PlayerUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Biometric Pill

private struct BiometricPill<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
    }
}

// MARK: - Demo Audio Bars

private struct DemoAudioBars: View {
    let color: Color
    @State private var isAnimating = false

    private let heights: [CGFloat] = [12, 18, 8, 15, 10]
    private let durations: [Double] = [0.5, 0.4, 0.6, 0.45, 0.55]

    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(color)
                    .frame(width: 2.5, height: isAnimating ? heights[i] : 4)
            }
        }
        .frame(height: 20)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Demo Meta Pill

private struct DemoMetaPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.mono(9))
            .foregroundColor(.white.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(.white.opacity(0.1))
            )
    }
}
