import SwiftUI

struct MusicTasteView: View {
  let onComplete: () -> Void

  @State private var currentStep = 0
  @State private var selectedGenres: Set<String>
  @State private var selectedSongs: [SpotifyTrack]
  @State private var energyPreference: String
  @State private var searchQuery = ""
  @State private var searchResults: [SpotifyTrack] = []
  @State private var isSearching = false
  @State private var searchError: String? = nil
  @State private var showFallbackInput = false
  @State private var fallbackText = ""
  @State private var debounceTask: Task<Void, Never>? = nil

  private let chipColors: [Color] = [
    .pink, .orange, .teal, .cyan, .green,
    .purple, .red, .indigo, .yellow, .blue,
  ]

  private let genres: [(name: String, color: Color)] = [
    ("Pop", .pink),
    ("Hip-Hop", .orange),
    ("R&B", .purple),
    ("Indie", .teal),
    ("Electronic", .cyan),
    ("Rock", .red),
    ("Arabic", .yellow),
    ("Latin", Color(red: 1.0, green: 0.4, blue: 0.3)),
    ("Classical", .indigo),
    ("Jazz", Color(red: 0.9, green: 0.7, blue: 0.2)),
    ("Country", Color(red: 0.8, green: 0.5, blue: 0.2)),
    ("Metal", Color(red: 0.7, green: 0.1, blue: 0.1)),
    ("Afrobeats", .green),
    ("K-Pop", Color(red: 1.0, green: 0.4, blue: 0.7)),
    ("Lo-Fi", Color(red: 0.5, green: 0.4, blue: 0.8)),
  ]

  private let energyOptions: [(label: String, value: String, color: Color)] = [
    ("Chill", "chill", AuraTheme.accent),
    ("Mellow", "mellow", AuraTheme.stressLow),
    ("Balanced", "balanced", AuraTheme.stressLow),
    ("Upbeat", "upbeat", AuraTheme.stressMed),
    ("High Energy", "high_energy", AuraTheme.stressHigh),
  ]

  init(onComplete: @escaping () -> Void) {
    self.onComplete = onComplete
    if let existing = MusicPreferences.load() {
      _selectedGenres = State(initialValue: Set(existing.genres))
      _selectedSongs = State(initialValue: existing.favoriteSongs.map { songString in
        SpotifyTrack(id: UUID().uuidString, name: songString, artistName: "", albumArtURL: nil)
      })
      _energyPreference = State(initialValue: existing.energyPreference)
    } else {
      _selectedGenres = State(initialValue: [])
      _selectedSongs = State(initialValue: [])
      _energyPreference = State(initialValue: "balanced")
    }
  }

  var body: some View {
    ZStack {
      AuraTheme.bg.edgesIgnoringSafeArea(.all)

      VStack(spacing: 0) {
        // Progress dots
        HStack(spacing: 8) {
          ForEach(0..<3, id: \.self) { i in
            Capsule()
              .fill(i <= currentStep ? AuraTheme.accent : AuraTheme.well)
              .frame(height: 4)
          }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)

        // Page content
        TabView(selection: $currentStep) {
          genrePage.tag(0)
          songsPage.tag(1)
          energyPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.3), value: currentStep)
      }
    }
    .onTapGesture {
      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }

  // MARK: - Step 1: Genres

  private var genrePage: some View {
    ScrollView {
      VStack(spacing: 24) {
        pageHeader(
          title: "What do you listen to?",
          subtitle: "Pick the genres you love. We'll use these to shape your soundtrack."
        )

        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
          ForEach(genres, id: \.name) { genre in
            SelectableChip(
              text: genre.name,
              color: genre.color,
              isSelected: selectedGenres.contains(genre.name)
            ) {
              if selectedGenres.contains(genre.name) {
                selectedGenres.remove(genre.name)
              } else {
                selectedGenres.insert(genre.name)
              }
            }
          }
        }

        Spacer().frame(height: 20)

        CustomButton(
          title: "Next",
          style: .primary,
          isDisabled: selectedGenres.isEmpty
        ) {
          withAnimation { currentStep = 1 }
        }
      }
      .padding(.all, 24)
    }
  }

  // MARK: - Step 2: Songs

  private var songsPage: some View {
    ScrollView {
      VStack(spacing: 24) {
        pageHeader(
          title: "Name some favorites",
          subtitle: "Search for songs or artists you love. We'll match the vibe."
        )

        // Search bar
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(AuraTheme.textTertiary)
          TextField("Search songs on Spotify...", text: $searchQuery)
            .font(.system(size: 15))
            .foregroundColor(AuraTheme.textPrimary)
            .autocorrectionDisabled()
            .onChange(of: searchQuery) { _, newValue in
              debounceSearch(query: newValue)
            }
          if !searchQuery.isEmpty {
            Button {
              searchQuery = ""
              searchResults = []
            } label: {
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(AuraTheme.textTertiary)
            }
          }
          if isSearching {
            ProgressView()
              .tint(AuraTheme.accent)
              .scaleEffect(0.7)
          }
        }
        .padding(12)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(AuraTheme.surface)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(AuraTheme.border, lineWidth: 1)
        )

        // Search results dropdown
        if !searchResults.isEmpty {
          VStack(spacing: 0) {
            ForEach(searchResults) { track in
              Button {
                addSong(track)
              } label: {
                HStack(spacing: 12) {
                  AsyncImage(url: track.albumArtURL) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                  } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                      .fill(AuraTheme.well)
                  }
                  .frame(width: 40, height: 40)
                  .clipShape(RoundedRectangle(cornerRadius: 6))

                  VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                      .font(.system(size: 14, weight: .medium))
                      .foregroundColor(AuraTheme.textPrimary)
                      .lineLimit(1)
                    Text(track.artistName)
                      .font(.system(size: 12))
                      .foregroundColor(AuraTheme.textSecondary)
                      .lineLimit(1)
                  }
                  Spacer()

                  if selectedSongs.contains(where: { $0.id == track.id }) {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(AuraTheme.accent)
                  }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
              }

              if track.id != searchResults.last?.id {
                Divider()
                  .background(AuraTheme.border)
              }
            }
          }
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(AuraTheme.surface)
          )
          .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
        }

        // Error message
        if let error = searchError {
          Text(error)
            .font(.system(size: 13))
            .foregroundColor(.orange.opacity(0.8))
        }

        // Fallback manual input
        if showFallbackInput {
          VStack(spacing: 8) {
            Text("Spotify is unavailable. Type a song manually:")
              .font(.system(size: 13))
              .foregroundColor(AuraTheme.textSecondary)
            HStack {
              TextField("e.g. Sunflower - Post Malone", text: $fallbackText)
                .font(.system(size: 15))
                .foregroundColor(AuraTheme.textPrimary)
                .onSubmit { addFallbackSong() }
              Button {
                addFallbackSong()
              } label: {
                Image(systemName: "plus.circle.fill")
                  .foregroundColor(AuraTheme.accent)
              }
            }
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(AuraTheme.surface)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(AuraTheme.border, lineWidth: 1)
            )
          }
        }

        // Selected songs chips
        if !selectedSongs.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Selected (\(selectedSongs.count))")
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(AuraTheme.textSecondary)

            MusicTasteFlowLayout(spacing: 8) {
              ForEach(Array(selectedSongs.enumerated()), id: \.element.id) { index, song in
                SongChip(track: song, color: chipColors[index % chipColors.count]) {
                  selectedSongs.removeAll { $0.id == song.id }
                }
              }
            }
          }
        }

        Spacer().frame(height: 20)

        HStack(spacing: 12) {
          Button {
            withAnimation { currentStep = 0 }
          } label: {
            Text("Back")
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(AuraTheme.textSecondary)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(AuraTheme.well)
              .cornerRadius(30)
          }

          CustomButton(
            title: "Next",
            style: .primary,
            isDisabled: selectedSongs.isEmpty
          ) {
            withAnimation { currentStep = 2 }
          }
        }
      }
      .padding(.all, 24)
    }
  }

  // MARK: - Step 3: Energy

  private var energyPage: some View {
    ScrollView {
      VStack(spacing: 24) {
        pageHeader(
          title: "What's your vibe?",
          subtitle: "Pick the energy level that fits you best."
        )

        VStack(spacing: 12) {
          ForEach(energyOptions, id: \.value) { option in
            Button {
              energyPreference = option.value
            } label: {
              HStack {
                Circle()
                  .fill(option.color)
                  .frame(width: 10, height: 10)
                Text(option.label)
                  .font(.system(size: 16, weight: .medium))
                  .foregroundColor(energyPreference == option.value ? AuraTheme.textPrimary : AuraTheme.textSecondary)
                Spacer()
                if energyPreference == option.value {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(option.color)
                }
              }
              .padding(16)
              .background(
                RoundedRectangle(cornerRadius: 14)
                  .fill(
                    energyPreference == option.value
                      ? option.color.opacity(0.1)
                      : AuraTheme.well
                  )
              )
              .overlay(
                RoundedRectangle(cornerRadius: 14)
                  .stroke(
                    energyPreference == option.value
                      ? option.color.opacity(0.4)
                      : Color.clear,
                    lineWidth: 1
                  )
              )
            }
          }
        }

        Spacer().frame(height: 20)

        HStack(spacing: 12) {
          Button {
            withAnimation { currentStep = 1 }
          } label: {
            Text("Back")
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(AuraTheme.textSecondary)
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(AuraTheme.well)
              .cornerRadius(30)
          }

          CustomButton(
            title: "Continue",
            style: .primary,
            isDisabled: false
          ) {
            savePreferences()
            onComplete()
          }
        }
      }
      .padding(.all, 24)
    }
  }

  // MARK: - Helpers

  private func pageHeader(title: String, subtitle: String) -> some View {
    VStack(spacing: 8) {
      Text(title)
        .font(AuraFont.brand(26))
        .foregroundColor(AuraTheme.textPrimary)

      Text(subtitle)
        .font(.system(size: 15))
        .multilineTextAlignment(.center)
        .foregroundColor(AuraTheme.textSecondary)
        .padding(.horizontal, 12)
    }
    .padding(.top, 20)
  }

  private func savePreferences() {
    let songs = selectedSongs.map { track in
      track.artistName.isEmpty ? track.name : track.displayString
    }

    let prefs = MusicPreferences(
      genres: Array(selectedGenres),
      favoriteSongs: songs,
      energyPreference: energyPreference
    )
    prefs.save()
  }

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
    guard !selectedSongs.contains(where: { $0.id == track.id }) else { return }
    selectedSongs.append(track)
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
    selectedSongs.append(track)
    fallbackText = ""
  }
}

// MARK: - Song Chip

private struct SongChip: View {
  let track: SpotifyTrack
  let color: Color
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: 6) {
      if let url = track.albumArtURL {
        AsyncImage(url: url) { image in
          image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
          Circle().fill(AuraTheme.well)
        }
        .frame(width: 20, height: 20)
        .clipShape(Circle())
      }

      Text(track.artistName.isEmpty ? track.name : "\(track.name) - \(track.artistName)")
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(color)
        .lineLimit(1)
        .truncationMode(.tail)

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(color.opacity(0.6))
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .frame(maxWidth: UIScreen.main.bounds.width - 56)
    .background(
      Capsule().fill(color.opacity(0.1))
    )
    .overlay(
      Capsule().stroke(color.opacity(0.3), lineWidth: 1)
    )
  }
}

// MARK: - Flow Layout

private struct MusicTasteFlowLayout: Layout {
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

// MARK: - Selectable Chip

private struct SelectableChip: View {
  let text: String
  let color: Color
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(text)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(isSelected ? color : AuraTheme.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
          Capsule()
            .fill(isSelected ? color.opacity(0.1) : AuraTheme.well)
        )
        .overlay(
          Capsule()
            .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
  }
}
