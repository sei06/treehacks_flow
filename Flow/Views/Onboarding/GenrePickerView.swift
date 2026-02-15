import SwiftUI

struct GenrePickerView: View {
    @ObservedObject var state: OnboardingState

    private let genres = [
        "Pop", "Hip-Hop", "R&B", "Indie", "Electronic",
        "Rock", "Arabic", "Latin", "Classical", "Jazz",
        "Country", "Metal", "Afrobeats", "K-Pop", "Lo-Fi",
    ]

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(currentStep: state.progressStep, totalSteps: state.totalSteps)
                .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("What do you listen to?")
                            .font(.sora(24, weight: .light))
                            .foregroundColor(AuraTheme.textPrimary)
                            .multilineTextAlignment(.center)

                        Text("Pick the genres you love.\nWe'll use these to shape your soundtrack.")
                            .font(.sora(14))
                            .foregroundColor(AuraTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(1.5)
                    }
                    .padding(.top, 24)

                    // Genre pills
                    GenreFlowLayout(spacing: 8) {
                        ForEach(genres, id: \.self) { genre in
                            GenrePill(
                                text: genre,
                                isSelected: state.selectedGenres.contains(genre)
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    if state.selectedGenres.contains(genre) {
                                        state.selectedGenres.remove(genre)
                                    } else {
                                        state.selectedGenres.insert(genre)
                                    }
                                }
                            }
                        }
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
                    disabled: state.selectedGenres.isEmpty
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state.next()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Genre Pill

private struct GenrePill: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.sora(14, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? AuraTheme.accent : AuraTheme.textSecondary)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(isSelected ? AuraTheme.accent.opacity(0.07) : AuraTheme.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? AuraTheme.accent.opacity(0.19) : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: isSelected ? .clear : .black.opacity(0.03),
                    radius: 3, y: 1
                )
        }
    }
}

// MARK: - Genre Flow Layout (centered)

private struct GenreFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        // Group positions by row for centering
        var rows: [[Int]] = []
        var currentRowY: CGFloat = -1

        for (index, position) in result.positions.enumerated() {
            if position.y != currentRowY {
                rows.append([index])
                currentRowY = position.y
            } else {
                rows[rows.count - 1].append(index)
            }
        }

        for row in rows {
            guard let firstIdx = row.first, let lastIdx = row.last else { continue }
            let firstPos = result.positions[firstIdx]
            let lastSize = subviews[lastIdx].sizeThatFits(.unspecified)
            let rowWidth = result.positions[lastIdx].x + lastSize.width - firstPos.x
            let xOffset = (bounds.width - rowWidth) / 2

            for idx in row {
                let pos = result.positions[idx]
                subviews[idx].place(
                    at: CGPoint(x: bounds.minX + pos.x + xOffset, y: bounds.minY + pos.y),
                    proposal: .unspecified
                )
            }
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
