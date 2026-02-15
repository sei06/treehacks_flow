import SwiftUI

struct MetricBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.monoMedium(20))
                .foregroundColor(color)
            Text(label)
                .font(.mono(9))
                .foregroundColor(AuraTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.09), lineWidth: 1)
        )
    }
}
