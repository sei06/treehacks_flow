import SwiftUI

struct PipelineCard: View {
    @ObservedObject var state: PipelineState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HOW WE GOT HERE")
                .font(.mono(9))
                .tracking(1.2)
                .foregroundColor(AuraTheme.textTertiary)
                .padding(.bottom, 4)

            // Step 1: Scene Captured
            PipelineStepView(
                number: 1,
                label: "SCENE CAPTURED",
                color: AuraTheme.accent,
                isActive: state.currentStep == .capturing,
                isDone: state.currentStep > .capturing,
                isLast: false
            ) {
                step1Content
            }

            // Step 2: Scene Analyzed
            PipelineStepView(
                number: 2,
                label: "SCENE ANALYZED",
                color: AuraTheme.accent,
                isActive: state.currentStep == .analyzing,
                isDone: state.currentStep > .analyzing,
                isLast: false
            ) {
                step2Content
            }

            // Step 3: Context Fused
            PipelineStepView(
                number: 3,
                label: "CONTEXT FUSED",
                color: state.stressColor,
                isActive: state.currentStep == .fusing,
                isDone: state.currentStep > .fusing,
                isLast: false
            ) {
                step3Content
            }

            // Step 4: AI Reasoning
            PipelineStepView(
                number: 4,
                label: "AI REASONING",
                color: AuraTheme.accent,
                isActive: state.currentStep == .reasoning,
                isDone: state.currentStep > .reasoning,
                isLast: false
            ) {
                step4Content
            }

            // Step 5: Composed & Playing
            PipelineStepView(
                number: 5,
                label: "COMPOSED & PLAYING",
                color: AuraTheme.accent,
                isActive: state.currentStep == .composing,
                isDone: state.currentStep > .composing,
                isLast: true
            ) {
                step5Content
            }
        }
        .padding(20)
        .background(AuraTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: AuraTheme.cardShadow, radius: 3, y: 1)
    }

    // MARK: - Step Contents

    @ViewBuilder
    private var step1Content: some View {
        if let photo = state.capturedPhoto {
            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Text("Captured from Ray-Ban glasses")
                                .font(.sora(11, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.15))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(8)
                    }
                )
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [AuraTheme.accent.opacity(0.08), AuraTheme.well],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 100)
                .overlay(
                    Text("📸 Captured from Ray-Ban glasses")
                        .font(.sora(11, weight: .medium))
                        .foregroundColor(AuraTheme.textTertiary)
                )
        }
    }

    @ViewBuilder
    private var step2Content: some View {
        Text(state.sceneDescription ?? "Analyzing environment...")
            .font(.sora(12))
            .foregroundColor(AuraTheme.textSecondary)
            .lineSpacing(4)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AuraTheme.bg)
            )
    }

    @ViewBuilder
    private var step3Content: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                MetricBox(value: "\(state.heartRate)", label: "BPM ↑", color: state.stressColor)
                MetricBox(value: "\(state.hrv)", label: "HRV (ms)", color: state.stressColor)
                MetricBox(value: "\(state.songs.count)", label: "songs", color: AuraTheme.accent)
            }

            if !state.songs.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(state.songs.prefix(6), id: \.self) { song in
                        Text(song)
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .foregroundColor(AuraTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(AuraTheme.accent.opacity(0.05)))
                            .overlay(Capsule().stroke(AuraTheme.accent.opacity(0.09)))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipped()
            }
        }
    }

    @ViewBuilder
    private var step4Content: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AuraTheme.accent.opacity(0.2))
                .frame(width: 3)

            Text("\"\(state.reasoning ?? "Analyzing...")\"")
                .font(.sora(13, weight: .light))
                .foregroundColor(AuraTheme.textSecondary)
                .lineSpacing(4)
                .padding(12)
        }
        .background(AuraTheme.bg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var step5Content: some View {
        Text(state.sunoPrompt ?? "Generating prompt...")
            .font(.mono(11))
            .foregroundColor(AuraTheme.textTertiary)
            .lineSpacing(4)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AuraTheme.bg)
            )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
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
