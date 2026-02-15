import SwiftUI

struct MusicInputChoiceView: View {
  let onChooseQuestionnaire: () -> Void
  let onChoosePlaylist: () -> Void

  var body: some View {
    ZStack {
      AuraTheme.bg.edgesIgnoringSafeArea(.all)

      VStack(spacing: 32) {
        VStack(spacing: 8) {
          Image(systemName: "music.note")
            .font(.system(size: 40))
            .foregroundColor(AuraTheme.accent)

          Text("How should we learn your taste?")
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(AuraTheme.textPrimary)
            .multilineTextAlignment(.center)

          Text("Pick how you'd like to tell us what you listen to.")
            .font(.system(size: 15))
            .foregroundColor(AuraTheme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
        }
        .padding(.top, 40)

        VStack(spacing: 16) {
          ChoiceCard(
            icon: "music.note.list",
            title: "Questionnaire",
            subtitle: "Pick genres, songs, and vibe",
            color: AuraTheme.accent,
            action: onChooseQuestionnaire
          )

          ChoiceCard(
            icon: "list.bullet.rectangle",
            title: "Spotify Playlist",
            subtitle: "Paste a playlist link",
            color: AuraTheme.stressLow,
            action: onChoosePlaylist
          )
        }
        .padding(.horizontal, 24)

        Spacer()
      }
    }
  }
}

// MARK: - Choice Card

private struct ChoiceCard: View {
  let icon: String
  let title: String
  let subtitle: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.system(size: 24))
          .foregroundColor(color)
          .frame(width: 48, height: 48)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(color.opacity(0.1))
          )

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AuraTheme.textPrimary)
          Text(subtitle)
            .font(.system(size: 14))
            .foregroundColor(AuraTheme.textSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(AuraTheme.textTertiary)
      }
      .padding(20)
      .auraCard(cornerRadius: 16)
    }
  }
}
