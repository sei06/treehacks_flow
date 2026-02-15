import SwiftUI

struct PlaylistImportView: View {
  let onComplete: () -> Void
  let onBack: () -> Void

  @State private var urlText = ""
  @State private var tracks: [SpotifyTrack] = []
  @State private var isLoading = false
  @State private var errorMessage: String? = nil
  @State private var hasFetched = false

  var body: some View {
    ZStack {
      AuraTheme.bg.edgesIgnoringSafeArea(.all)

      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 8) {
            Text("Import Spotify Playlist")
              .font(.system(size: 26, weight: .bold))
              .foregroundColor(AuraTheme.textPrimary)

            Text("Paste a Spotify playlist link below.")
              .font(.system(size: 15))
              .foregroundColor(AuraTheme.textSecondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal, 12)
          }
          .padding(.top, 20)

          // URL input
          HStack {
            Image(systemName: "link")
              .foregroundColor(AuraTheme.textTertiary)
            TextField("https://open.spotify.com/playlist/...", text: $urlText)
              .font(.system(size: 14))
              .foregroundColor(AuraTheme.textPrimary)
              .autocorrectionDisabled()
              .textInputAutocapitalization(.never)
              .onChange(of: urlText) { _, newValue in
                if let playlistId = SpotifyService.extractPlaylistId(from: newValue) {
                  fetchPlaylist(id: playlistId)
                }
              }
            if !urlText.isEmpty {
              Button {
                urlText = ""
                tracks = []
                hasFetched = false
                errorMessage = nil
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(AuraTheme.textTertiary)
              }
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

          // Loading
          if isLoading {
            HStack(spacing: 8) {
              ProgressView()
                .tint(AuraTheme.accent)
              Text("Fetching playlist...")
                .font(.system(size: 14))
                .foregroundColor(AuraTheme.textSecondary)
            }
            .padding(.vertical, 8)
          }

          // Error
          if let error = errorMessage {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
              Text(error)
                .font(.system(size: 14))
                .foregroundColor(.orange)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
            )
          }

          // Track list
          if !tracks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
              Text("\(tracks.count) songs found")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AuraTheme.textTertiary)

              VStack(spacing: 0) {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                  HStack(spacing: 12) {
                    Text("\(index + 1)")
                      .font(AuraFont.data(12))
                      .foregroundColor(AuraTheme.textTertiary)
                      .frame(width: 24)

                    AsyncImage(url: track.albumArtURL) { image in
                      image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                      RoundedRectangle(cornerRadius: 4)
                        .fill(AuraTheme.well)
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

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
                  }
                  .padding(.vertical, 8)
                  .padding(.horizontal, 12)

                  if index < tracks.count - 1 {
                    Divider()
                      .background(AuraTheme.border)
                      .padding(.leading, 84)
                  }
                }
              }
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(AuraTheme.surface)
              )
            }
          }

          Spacer().frame(height: 20)

          // Buttons
          HStack(spacing: 12) {
            Button {
              onBack()
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
              title: "Import Songs",
              style: .primary,
              isDisabled: tracks.isEmpty
            ) {
              importSongs()
            }
          }
        }
        .padding(.all, 24)
      }
    }
    .onTapGesture {
      UIApplication.shared.sendAction(
        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
  }

  private func fetchPlaylist(id: String) {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil
    tracks = []
    hasFetched = false

    Task {
      do {
        let result = try await SpotifyService.fetchPlaylistTracks(playlistId: id)
        await MainActor.run {
          tracks = result
          isLoading = false
          hasFetched = true
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

  private func importSongs() {
    let songs = tracks.map { $0.displayString }
    let prefs = MusicPreferences(
      genres: [],
      favoriteSongs: songs,
      energyPreference: "balanced"
    )
    prefs.save()
    onComplete()
  }
}
