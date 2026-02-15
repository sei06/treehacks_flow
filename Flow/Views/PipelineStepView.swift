import SwiftUI

struct PipelineStepView<Content: View>: View {
    let number: Int
    let label: String
    let color: Color
    let isActive: Bool
    let isDone: Bool
    let isLast: Bool
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left column: step indicator + connector line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(circleBackground)
                        .frame(width: 28, height: 28)
                    Circle()
                        .stroke(circleBorder, lineWidth: 1.5)
                        .frame(width: 28, height: 28)

                    if isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(color)
                    } else {
                        Text("\(number)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isActive ? color : AuraTheme.textTertiary)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(isDone ? color.opacity(0.13) : AuraTheme.border)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 28)

            // Right column: label + content
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.mono(9))
                    .fontWeight(.semibold)
                    .tracking(1)
                    .foregroundColor((isActive || isDone) ? color : AuraTheme.textTertiary)

                if isActive || isDone {
                    content()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.bottom, 14)
        }
    }

    private var circleBackground: Color {
        if isDone { return color.opacity(0.1) }
        if isActive { return color.opacity(0.07) }
        return AuraTheme.well
    }

    private var circleBorder: Color {
        if isDone { return color.opacity(0.27) }
        if isActive { return color.opacity(0.2) }
        return AuraTheme.border
    }
}
