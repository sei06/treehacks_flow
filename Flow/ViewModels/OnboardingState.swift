import SwiftUI

enum OnboardingPath {
    case tasteMethod
    case genrePicker
    case songSearch
    case spotifyPlaylist
}

class OnboardingState: ObservableObject {
    @Published var currentScreen: OnboardingPath = .tasteMethod
    @Published var selectedMethod: String? = nil  // "questionnaire" or "spotify"

    // Genre picker
    @Published var selectedGenres: Set<String> = []

    // Song search
    @Published var selectedSongs: [SpotifyTrack] = []

    // Spotify
    @Published var playlistURL: String = ""
    @Published var playlistTracks: [SpotifyTrack] = []

    var progressStep: Int {
        switch currentScreen {
        case .tasteMethod: return 0
        case .genrePicker, .spotifyPlaylist: return 1
        case .songSearch: return 2
        }
    }

    var totalSteps: Int {
        selectedMethod == "spotify" ? 2 : 3
    }

    func next() {
        switch currentScreen {
        case .tasteMethod:
            currentScreen = selectedMethod == "questionnaire" ? .genrePicker : .spotifyPlaylist
        case .genrePicker:
            currentScreen = .songSearch
        case .songSearch, .spotifyPlaylist:
            break
        }
    }

    func back() {
        switch currentScreen {
        case .genrePicker, .spotifyPlaylist:
            currentScreen = .tasteMethod
        case .songSearch:
            currentScreen = .genrePicker
        default: break
        }
    }

    func savePreferences() {
        let songs: [String]
        if selectedMethod == "spotify" {
            songs = playlistTracks.map { $0.displayString }
        } else {
            songs = selectedSongs.map { track in
                track.artistName.isEmpty ? track.name : track.displayString
            }
        }

        let prefs = MusicPreferences(
            genres: Array(selectedGenres),
            favoriteSongs: songs,
            energyPreference: "balanced"
        )
        prefs.save()
    }
}
