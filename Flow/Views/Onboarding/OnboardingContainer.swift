import SwiftUI

struct OnboardingContainer: View {
    @StateObject private var state = OnboardingState()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            AuraTheme.bg.ignoresSafeArea()

            Group {
                switch state.currentScreen {
                case .tasteMethod:
                    TasteMethodView(state: state)
                        .transition(.move(edge: .trailing))

                case .genrePicker:
                    GenrePickerView(state: state)
                        .transition(.move(edge: .trailing))

                case .songSearch:
                    SongSearchView(state: state, onComplete: onComplete)
                        .transition(.move(edge: .trailing))

                case .spotifyPlaylist:
                    SpotifyPlaylistView(state: state, onComplete: onComplete)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: state.currentScreen)
        }
    }
}

extension OnboardingPath: Equatable {}
