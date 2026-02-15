import SwiftUI

struct NowPlayingView: View {
  let clip: SunoClip
  let isPlaying: Bool
  let onPlayPause: () -> Void
  let onDismiss: () -> Void

  var body: some View {
    ZStack {
      // Album art color bleed
      LinearGradient(
        colors: [AuraTheme.accent.opacity(0.07), Color.clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 200)
      .frame(maxWidth: .infinity)
      .offset(y: -80)

      VStack(alignment: .leading, spacing: 16) {
        // Header
        HStack {
          Image(systemName: "music.note")
            .foregroundColor(AuraTheme.accent)
          Text("Now Playing")
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(AuraTheme.textPrimary)
          Spacer()
          Button(action: onDismiss) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 20))
              .foregroundColor(AuraTheme.textTertiary)
          }
        }

        // Cover art + title + controls
        HStack(spacing: 12) {
          if let imageUrlString = clip.imageUrl,
            let imageUrl = URL(string: imageUrlString)
          {
            AsyncImage(url: imageUrl) { image in
              image.resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              RoundedRectangle(cornerRadius: 8)
                .fill(
                  LinearGradient(
                    colors: [AuraTheme.accent.opacity(0.18), AuraTheme.well],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .overlay(
                  Image(systemName: "music.note")
                    .foregroundColor(AuraTheme.textTertiary)
                )
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: AuraTheme.artShadow, radius: 8, y: 4)
          } else {
            RoundedRectangle(cornerRadius: 8)
              .fill(
                LinearGradient(
                  colors: [AuraTheme.accent.opacity(0.18), AuraTheme.well],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .overlay(
                Image(systemName: "music.note")
                  .foregroundColor(AuraTheme.textTertiary)
              )
              .frame(width: 60, height: 60)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text(clip.title ?? "Generating...")
              .font(AuraFont.brand(15))
              .foregroundColor(AuraTheme.textPrimary)
              .lineLimit(2)
            Text(clip.status == "complete" ? "Ready" : "Streaming...")
              .font(.system(size: 13))
              .foregroundColor(AuraTheme.textTertiary)
          }

          Spacer()

          Button(action: onPlayPause) {
            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
              .font(.system(size: 44))
              .foregroundColor(AuraTheme.accent)
          }
        }
      }
      .padding(16)
      .auraCard(cornerRadius: 16)
    }
  }
}
