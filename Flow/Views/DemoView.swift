import AVFoundation
import SwiftUI

struct DemoView: View {
    @ObservedObject var viewModel: StreamSessionViewModel
    @ObservedObject var wearablesVM: WearablesViewModel
    @StateObject private var pipeline = PipelineState()
    @State private var showMusicTasteEditor = false
    @State private var pipelineTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            AuraTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // FIXED TOP: header + toggles (always tappable)
                VStack(spacing: 12) {
                    headerBar
                    stressToggle
                    vocalsToggle
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // SCROLLABLE MIDDLE: cards and content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Composing placeholder (while pipeline is active)
                        if pipeline.currentStep != .idle && pipeline.currentStep != .playing {
                            composingPlaceholder
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }

                        // Now Playing Card (slides in when music ready)
                        if pipeline.currentStep == .playing {
                            NowPlayingCard(state: pipeline, onNewMoment: { newMoment() })
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        // Compose orb + button (visible when idle)
                        if pipeline.currentStep == .idle {
                            VStack(spacing: 20) {
                                if !viewModel.isSessionReady {
                                    HStack(spacing: 8) {
                                        ProgressView().tint(AuraTheme.accent).scaleEffect(0.8)
                                        Text(viewModel.hasActiveDevice
                                             ? "Connecting to glasses..."
                                             : "Waiting for an active device")
                                        .font(.sora(14))
                                        .foregroundColor(AuraTheme.textSecondary)
                                    }
                                }

                                Spacer().frame(height: 8)

                                composeButton
                            }
                            .padding(.top, 20)
                        }

                        // Pipeline Card (visible once pipeline has started)
                        if pipeline.currentStep.rawValue >= PipelineState.Step.capturing.rawValue {
                            PipelineCard(state: pipeline)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                }

                // FIXED BOTTOM: new moment button (always tappable when playing)
                if pipeline.currentStep == .playing {
                    newMomentButton
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $showMusicTasteEditor) {
            MusicTasteView { showMusicTasteEditor = false }
        }
        .onAppear {
            loadMusicTaste()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("flow")
                .font(.sora(28, weight: .light))
                .foregroundColor(AuraTheme.textPrimary)
                .tracking(1)

            Spacer()

            StressPill(level: pipeline.stressLevel)

            Menu {
                Button { showMusicTasteEditor = true } label: {
                    Label("Edit Music Taste", systemImage: "music.note.list")
                }
                Button("Disconnect", role: .destructive) {
                    wearablesVM.disconnectGlasses()
                }
            } label: {
                Image(systemName: "gearshape")
                    .foregroundColor(AuraTheme.textSecondary)
                    .frame(width: 28, height: 28)
            }
        }
    }

    // MARK: - Stress Toggle

    private var stressToggle: some View {
        HStack(spacing: 0) {
            ForEach(["high", "moderate", "low"], id: \.self) { level in
                let isSelected = pipeline.stressLevel == level
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pipeline.stressLevel = level
                        updateBiometrics(for: level)
                    }
                } label: {
                    Text(level.capitalized)
                        .font(.sora(12, weight: .semibold))
                        .foregroundColor(isSelected ? AuraTheme.stressColor(for: level) : AuraTheme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .background(
                            isSelected
                            ? AnyView(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AuraTheme.surface)
                                    .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
                            )
                            : AnyView(EmptyView())
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AuraTheme.well)
        )
    }

    private var vocalsToggle: some View {
        HStack(spacing: 0) {
            ForEach(["Vocals", "Instrumental"], id: \.self) { option in
                let isSelected = option == "Vocals" ? !pipeline.makeInstrumental : pipeline.makeInstrumental
                Text(option)
                    .font(.sora(12, weight: .semibold))
                    .foregroundColor(isSelected ? AuraTheme.accent : AuraTheme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        isSelected
                        ? AnyView(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AuraTheme.surface)
                                .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
                        )
                        : AnyView(EmptyView())
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("[UI] Vocals toggle tapped: \(option)")
                        withAnimation(.easeInOut(duration: 0.2)) {
                            pipeline.makeInstrumental = option == "Instrumental"
                        }
                    }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AuraTheme.well)
        )
    }

    // MARK: - Compose Button

    private var composeButton: some View {
        Button {
            guard viewModel.isSessionReady else { return }
            pipelineTask?.cancel()
            pipelineTask = Task { await runPipeline() }
        } label: {
            VStack(spacing: 16) {
                BreathingOrb(
                    color: pipeline.stressColor,
                    size: 120
                )
                .allowsHitTesting(false)

                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .font(.system(size: 14, weight: .medium))
                    Text("Compose")
                        .font(.sora(15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(AuraTheme.accent)
                        .shadow(color: AuraTheme.accent.opacity(0.25), radius: 12, y: 4)
                )
            }
        }
        .buttonStyle(ComposeButtonStyle())
        .disabled(!viewModel.isSessionReady)
        .opacity(viewModel.isSessionReady ? 1 : 0.5)
    }

    // MARK: - New Moment Button

    private var newMomentButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 14, weight: .medium))
            Text("new moment")
                .font(.sora(15, weight: .semibold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(AuraTheme.accent)
                .shadow(color: AuraTheme.accent.opacity(0.25), radius: 12, y: 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            print("[UI] New moment tapped!")
            newMoment()
        }
    }

    // MARK: - Composing Placeholder

    private var composingPlaceholder: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 16)
                .fill(AuraTheme.well)
                .frame(height: 120)
                .shimmer()

            Text("Composing your soundtrack...")
                .font(.sora(16, weight: .light))
                .foregroundColor(AuraTheme.textTertiary)

            TypingIndicator(color: AuraTheme.accent)
        }
        .padding(20)
        .background(AuraTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
    }

    // MARK: - Pipeline Orchestration

    @MainActor
    private func runPipeline() async {
        let pipelineStart = Date()
        print("[Pipeline] Starting pipeline")

        // Load songs
        loadMusicTaste()

        // Map stress level to StressLevel enum for GeminiService
        let stressEnum: StressLevel = switch pipeline.stressLevel {
        case "high": .high
        case "moderate": .moderate
        case "low": .low
        default: .high
        }

        // Step 1: Capture photo
        withAnimation(.easeOut(duration: 0.4)) {
            pipeline.currentStep = .capturing
        }
        guard let frame = viewModel.currentVideoFrame else {
            print("[Pipeline] No video frame available, returning to idle")
            withAnimation { pipeline.currentStep = .idle }
            return
        }
        pipeline.capturedPhoto = frame
        print("[Pipeline] Photo captured at \(String(format: "%.1f", Date().timeIntervalSince(pipelineStart)))s")

        // Step 2: Analyze scene (LLM call)
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard !Task.isCancelled else { print("[Pipeline] Cancelled"); return }
        withAnimation(.easeOut(duration: 0.4)) {
            pipeline.currentStep = .analyzing
        }

        do {
            print("[Pipeline] Calling LLM (Gemini)...")
            let llmStart = Date()
            let response = try await GeminiService.generateMusicTherapy(
                frame,
                instrumental: pipeline.makeInstrumental,
                stressLevel: stressEnum
            )
            guard !Task.isCancelled else { print("[Pipeline] Cancelled after LLM"); return }
            let llmElapsed = Date().timeIntervalSince(llmStart)
            print("[Pipeline] LLM done in \(String(format: "%.1f", llmElapsed))s")
            print("[Pipeline] Scene: \(response.sceneDescription.prefix(80))...")
            print("[Pipeline] Suno prompt: \(response.sunoPrompt.prefix(100))...")
            print("[Pipeline] Suno tags: \(response.sunoTags)")

            // Step 2 done: scene description
            withAnimation(.easeOut(duration: 0.4)) {
                pipeline.sceneDescription = response.sceneDescription
            }

            // Step 3: Context fused
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { print("[Pipeline] Cancelled"); return }
            withAnimation(.easeOut(duration: 0.4)) {
                pipeline.currentStep = .fusing
            }

            // Step 4: AI reasoning
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { print("[Pipeline] Cancelled"); return }
            withAnimation(.easeOut(duration: 0.4)) {
                pipeline.currentStep = .reasoning
                pipeline.reasoning = response.reasoning
            }

            // Step 5: Composing
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { print("[Pipeline] Cancelled"); return }
            withAnimation(.easeOut(duration: 0.4)) {
                pipeline.currentStep = .composing
                pipeline.sunoPrompt = response.sunoPrompt
                pipeline.sunoTags = response.sunoTags
                pipeline.trackBPM = response.targetBpm
                pipeline.trackMood = response.mood
                pipeline.trackEnergy = response.energy
            }

            // Generate music with Suno
            print("[Pipeline] Calling Suno generate at \(String(format: "%.1f", Date().timeIntervalSince(pipelineStart)))s...")
            let sunoStart = Date()
            let clipId = try await SunoService.generate(
                topic: response.sunoPrompt,
                tags: response.sunoTags,
                makeInstrumental: pipeline.makeInstrumental
            )
            guard !Task.isCancelled else { print("[Pipeline] Cancelled after Suno generate"); return }
            print("[Pipeline] Suno clip ID: \(clipId) (took \(String(format: "%.1f", Date().timeIntervalSince(sunoStart)))s)")

            // Poll until audio available
            var attempts = 0
            var hasStartedPlayback = false
            while attempts < 60 {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s polling
                guard !Task.isCancelled else { print("[Pipeline] Cancelled during polling"); return }
                let clip = try await SunoService.fetchClip(id: clipId)
                let elapsed = Date().timeIntervalSince(pipelineStart)
                print("[Pipeline] Poll #\(attempts + 1): status=\(clip.status), audioUrl=\(clip.audioUrl != nil ? "YES" : "nil"), elapsed=\(String(format: "%.0f", elapsed))s")

                if clip.status == "streaming" || clip.status == "complete" {
                    if let urlStr = clip.audioUrl, let audioURL = URL(string: urlStr) {
                        if !hasStartedPlayback {
                            print("[Pipeline] Starting playback from \(clip.status) status at \(String(format: "%.1f", elapsed))s")
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                pipeline.currentStep = .playing
                                pipeline.trackTitle = clip.title ?? "Untitled"
                                pipeline.audioURL = audioURL
                                if let imgStr = clip.imageUrl {
                                    pipeline.albumArtURL = URL(string: imgStr)
                                }
                                pipeline.isPlaying = true
                            }
                            startPlayback(url: audioURL)
                            hasStartedPlayback = true
                        }
                        if clip.status == "complete" {
                            print("[Pipeline] COMPLETE at \(String(format: "%.1f", elapsed))s")
                            break
                        }
                    }
                }

                if clip.status == "error" {
                    print("[Pipeline] ERROR status from Suno at \(String(format: "%.1f", elapsed))s")
                    pipeline.currentStep = .idle
                    return
                }

                attempts += 1
            }

            print("[Pipeline] Total time: \(String(format: "%.1f", Date().timeIntervalSince(pipelineStart)))s")

        } catch {
            guard !Task.isCancelled else { print("[Pipeline] Cancelled"); return }
            print("[Pipeline] ERROR: \(error.localizedDescription) at \(String(format: "%.1f", Date().timeIntervalSince(pipelineStart)))s")
            withAnimation {
                pipeline.currentStep = .idle
            }
        }
    }

    private func newMoment() {
        print("[Pipeline] newMoment() called — cancelling old task, stopping playback")
        // Cancel any in-flight pipeline (stops old polling loop)
        pipelineTask?.cancel()
        pipelineTask = nil

        viewModel.stopPlayback()
        withAnimation(.easeInOut(duration: 0.4)) {
            pipeline.currentStep = .composing
            pipeline.trackTitle = nil
            pipeline.audioURL = nil
            pipeline.albumArtURL = nil
            pipeline.isPlaying = false
        }
        pipelineTask = Task {
            await runPipeline()
        }
    }

    private func startPlayback(url: URL) {
        viewModel.startPlayback(url: url)
    }

    private func updateBiometrics(for level: String) {
        switch level {
        case "high":
            pipeline.heartRate = 92
            pipeline.hrv = 15
        case "moderate":
            pipeline.heartRate = 78
            pipeline.hrv = 32
        case "low":
            pipeline.heartRate = 65
            pipeline.hrv = 55
        default: break
        }
    }

    private func loadMusicTaste() {
        if let prefs = MusicPreferences.load() {
            pipeline.songs = prefs.favoriteSongs
        }
    }
}

// MARK: - Compose Button Style

private struct ComposeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
