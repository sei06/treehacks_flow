import SwiftUI

struct SpotifyPlaylistView: View {
    @ObservedObject var state: OnboardingState
    var onComplete: () -> Void

    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var hasFetched = false
    @State private var playlistName: String? = nil
    @State private var isURLFocused = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: state.progressStep, totalSteps: state.totalSteps)
                .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Paste your playlist")
                            .font(.sora(24, weight: .light))
                            .foregroundColor(AuraTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("We'll pull your tracks and\nmatch the vibe.")
                            .font(.sora(14))
                            .foregroundColor(AuraTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1.5)
                    }
                    .padding(.top, 24)

                    // URL input
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .font(.system(size: 16))
                            .foregroundColor(AuraTheme.textTertiary)

                        TextField("Paste Spotify playlist link...", text: $state.playlistURL, onEditingChanged: { editing in
                            isURLFocused = editing
                        })
                        .font(.sora(14))
                        .foregroundColor(AuraTheme.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: state.playlistURL) { _, newValue in
                            if let playlistId = SpotifyService.extractPlaylistId(from: newValue) {
                                fetchPlaylist(id: playlistId)
                            }
                        }

                        if !state.playlistURL.isEmpty {
                            Button {
                                state.playlistURL = ""
                                state.playlistTracks = []
                                hasFetched = false
                                errorMessage = nil
                                playlistName = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AuraTheme.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AuraTheme.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isURLFocused ? AuraTheme.accent.opacity(0.19) : AuraTheme.border,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.03), radius: 3, y: 1)

                    // Loading
                    if isLoading {
                        HStack(spacing: 8) {
                            ProgressView()
                                .tint(AuraTheme.accent)
                            Text("Fetching playlist...")
                                .font(.sora(14))
                                .foregroundColor(AuraTheme.textSecondary)
                        }
                        .padding(.vertical, 8)
                    }

                    // Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.sora(13))
                            .foregroundColor(AuraTheme.stressHigh)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Success card
                    if hasFetched && !state.playlistTracks.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(AuraTheme.stressLow)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Found \(state.playlistTracks.count) tracks")
                                    .font(.sora(15, weight: .medium))
                                    .foregroundColor(AuraTheme.textPrimary)

                                if let name = playlistName {
                                    Text(name)
                                        .font(.sora(12))
                                        .foregroundColor(AuraTheme.textTertiary)
                                }
                            }

                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AuraTheme.stressLow.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AuraTheme.stressLow.opacity(0.15), lineWidth: 1)
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }

            // Bottom buttons
            HStack(spacing: 12) {
                OnboardingButton(label: "Back", isSecondary: true) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state.back()
                    }
                }
                .frame(width: 120)

                OnboardingButton(
                    label: "Next",
                    disabled: state.playlistTracks.isEmpty
                ) {
                    state.savePreferences()
                    onComplete()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    // MARK: - Fetch Playlist

    private func fetchPlaylist(id: String) {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        state.playlistTracks = []
        hasFetched = false
        playlistName = nil

        Task {
            do {
                let result = try await SpotifyService.fetchPlaylistTracks(playlistId: id)
                await MainActor.run {
                    state.playlistTracks = result
                    isLoading = false
                    hasFetched = true
                    playlistName = "Spotify Playlist"
                    if result.isEmpty {
                        errorMessage = "This playlist appears to be empty."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
