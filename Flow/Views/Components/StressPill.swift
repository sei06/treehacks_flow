import SwiftUI

struct StressPill: View {
    let level: String
    private var color: Color { AuraTheme.stressColor(for: level) }

    var body: some View {
        HStack(spacing: 6) {
            BreathingDot(color: color)

            Text("\(level.capitalized) Stress")
                .font(.mono(10))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(color.opacity(0.07))
        )
        .overlay(
            Capsule().stroke(color.opacity(0.13), lineWidth: 1)
        )
    }
}

struct BreathingDot: View {
    @State private var isBreathing = false
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .scaleEffect(isBreathing ? 1.3 : 1.0)
            .opacity(isBreathing ? 0.6 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }
}
