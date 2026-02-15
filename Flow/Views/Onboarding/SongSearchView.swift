import SwiftUI

struct SongSearchView: View {
    @ObservedObject var state: OnboardingState
    var onComplete: () -> Void

    @State private var searchQuery = ""
    @State private var searchResults: [SpotifyTrack] = []
    @State private var isSearching = false
    @State private var searchError: String? = nil
    @State private var showFallbackInput = false
    @State private var fallbackText = ""
    @State private var debounceTask: Task<Void, Never>? = nil
    @State private var isSearchFocused = false

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: state.progressStep, totalSteps: state.totalSteps)
                .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Name some favorites")
                            .font(.sora(24, weight: .light))
                            .foregroundColor(AuraTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Search for songs or artists you love.\nWe'll match the vibe.")
                            .font(.sora(14))
                            .foregroundColor(AuraTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1.5)
                    }
                    .padding(.top, 24)

                    // Search input
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(AuraTheme.textTertiary)

                        TextField("Search songs on Spotify...", text: $searchQuery, onEditingChanged: { editing in
                            isSearchFocused = editing
                        })
                        .font(.sora(14))
                        .foregroundColor(AuraTheme.textPrimary)
                        .autocorrectionDisabled()
                        .onChange(of: searchQuery) { _, newValue in
                            debounceSearch(query: newValue)
                        }

                        if isSearching {
                            ProgressView()
                                .tint(AuraTheme.accent)
                                .scaleEffect(0.7)
                        }

                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                                searchResults = []
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
                                isSearchFocused ? AuraTheme.accent.opacity(0.19) : AuraTheme.border,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.03), radius: 3, y: 1)

                    // Search results dropdown
                    if !searchResults.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(searchResults) { track in
                                Button {
                                    addSong(track)
                                } label: {
                                    HStack(spacing: 12) {
                                        // Album art placeholder
                                        if let artURL = track.albumArtURL {
                                            AsyncImage(url: artURL) { image in
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: {
                                                albumArtPlaceholder
                                            }
                                            .frame(width: 40, height: 40)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        } else {
                                            albumArtPlaceholder
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(track.name)
                                                .font(.sora(13, weight: .medium))
                                                .foregroundColor(AuraTheme.textPrimary)
                                                .lineLimit(1)
                                                .truncationMode(.tail)

                                            Text(track.artistName)
                                                .font(.sora(11))
                                                .foregroundColor(AuraTheme.textTertiary)
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        if state.selectedSongs.contains(where: { $0.id == track.id }) {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AuraTheme.accent)
                                        } else {
                                            Text("+")
                                                .font(.system(size: 16, weight: .light))
                                                .foregroundColor(AuraTheme.accent)
                                        }
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }

                                if track.id != searchResults.last?.id {
                                    Divider()
                                        .background(AuraTheme.well)
                                        .padding(.leading, 68)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AuraTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AuraTheme.border, lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 16, y: 4)
                    }

                    // Error
                    if let error = searchError {
                        Text(error)
                            .font(.sora(13))
                            .foregroundColor(AuraTheme.stressHigh)
                    }

                    // Fallback manual input
                    if showFallbackInput {
                        VStack(spacing: 8) {
                            Text("Spotify is unavailable. Type a song manually:")
                                .font(.sora(13))
                                .foregroundColor(AuraTheme.textSecondary)

                            HStack {
                                TextField("e.g. Sunflower - Post Malone", text: $fallbackText)
                                    .font(.sora(14))
                                    .foregroundColor(AuraTheme.textPrimary)
                                    .onSubmit { addFallbackSong() }

                                Button {
                                    addFallbackSong()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(AuraTheme.accent)
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AuraTheme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(AuraTheme.border, lineWidth: 1.5)
                            )
                        }
                    }

                    // Selected songs
                    if !state.selectedSongs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SELECTED (\(state.selectedSongs.count))")
                                .font(.monoMedium(9))
                                .foregroundColor(AuraTheme.textTertiary)
                                .tracking(1)

                            SelectedSongsFlowLayout(spacing: 8) {
                                ForEach(state.selectedSongs) { song in
                                    SelectedSongPill(track: song) {
                                        withAnimation(.spring(response: 0.3)) {
                                            state.selectedSongs.removeAll { $0.id == song.id }
                                        }
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                    disabled: state.selectedSongs.isEmpty
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

    // MARK: - Album Art Placeholder

    private var albumArtPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(
                LinearGradient(
                    colors: [AuraTheme.accent.opacity(0.1), AuraTheme.well],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 40, height: 40)
    }

    // MARK: - Search Logic

    private func debounceSearch(query: String) {
        debounceTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }

            await MainActor.run { isSearching = true }

            do {
                let results = try await SpotifyService.searchTracks(query: query)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    searchError = nil
                    showFallbackInput = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                    searchError = "Could not search Spotify"
                    showFallbackInput = true
                }
            }
        }
    }

    private func addSong(_ track: SpotifyTrack) {
        guard !state.selectedSongs.contains(where: { $0.id == track.id }) else { return }
        withAnimation(.spring(response: 0.3)) {
            state.selectedSongs.append(track)
        }
        searchQuery = ""
        searchResults = []
    }

    private func addFallbackSong() {
        let text = fallbackText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let track = SpotifyTrack(
            id: UUID().uuidString,
            name: text,
            artistName: "",
            albumArtURL: nil
        )
        withAnimation(.spring(response: 0.3)) {
            state.selectedSongs.append(track)
        }
        fallbackText = ""
    }
}

// MARK: - Selected Song Pill

private struct SelectedSongPill: View {
    let track: SpotifyTrack
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(track.artistName.isEmpty ? track.name : "\(track.name) - \(track.artistName)")
                .font(.sora(12))
                .foregroundColor(AuraTheme.accent)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 250)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AuraTheme.accent.opacity(0.5))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule().fill(AuraTheme.accent.opacity(0.05))
        )
        .overlay(
            Capsule().stroke(AuraTheme.accent.opacity(0.09), lineWidth: 1.5)
        )
    }
}

// MARK: - Selected Songs Flow Layout

private struct SelectedSongsFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
