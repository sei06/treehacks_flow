import SwiftUI

struct TasteMethodView: View {
    @ObservedObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: state.progressStep, totalSteps: state.totalSteps)
                .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Icon
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                        .foregroundColor(AuraTheme.accent)
                        .frame(width: 48, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AuraTheme.well)
                        )
                        .padding(.top, 32)

                    // Header
                    VStack(spacing: 8) {
                        Text("How should we learn\nyour taste?")
                            .font(.sora(24, weight: .light))
                            .foregroundColor(AuraTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Pick how you'd like to tell us\nwhat you listen to.")
                            .font(.sora(14))
                            .foregroundColor(AuraTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1.5)
                    }

                    // Option cards
                    VStack(spacing: 12) {
                        MethodOptionCard(
                            icon: "music.note.list",
                            title: "Questionnaire",
                            subtitle: "Pick genres, songs, and vibe",
                            isSelected: state.selectedMethod == "questionnaire"
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                state.selectedMethod = "questionnaire"
                            }
                        }

                        MethodOptionCard(
                            icon: "list.bullet.rectangle",
                            title: "Spotify Playlist",
                            subtitle: "Paste a playlist link",
                            isSelected: state.selectedMethod == "spotify"
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                state.selectedMethod = "spotify"
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }

            // Bottom button
            OnboardingButton(
                label: "Next",
                disabled: state.selectedMethod == nil
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    state.next()
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Method Option Card

private struct MethodOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon container
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AuraTheme.accent : AuraTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? AuraTheme.accent.opacity(0.07) : AuraTheme.well)
                    )

                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.sora(15, weight: .medium))
                        .foregroundColor(AuraTheme.textPrimary)

                    Text(subtitle)
                        .font(.sora(12))
                        .foregroundColor(AuraTheme.textTertiary)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(AuraTheme.textTertiary)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AuraTheme.accent.opacity(0.05) : AuraTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AuraTheme.accent.opacity(0.19) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 3, y: 1)
        }
    }
}
