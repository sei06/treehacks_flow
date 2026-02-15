import SwiftUI

struct BreathingOrb: View {
    let color: Color
    let size: CGFloat
    var label: String? = nil
    var onTap: (() -> Void)? = nil

    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.3), color.opacity(0.1), .clear],
                            center: UnitPoint(x: 0.4, y: 0.38),
                            startRadius: 0,
                            endRadius: size / 2
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(Circle().stroke(color.opacity(0.15), lineWidth: 1.5))
                    .scaleEffect(isBreathing ? 1.06 : 1.0)
                    .shadow(color: color.opacity(isBreathing ? 0.12 : 0), radius: isBreathing ? 20 : 8)

                // Inner circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [color.opacity(0.5), color.opacity(0.22)],
                            center: UnitPoint(x: 0.45, y: 0.4),
                            startRadius: 0,
                            endRadius: size / 4
                        )
                    )
                    .frame(width: size * 0.46, height: size * 0.46)
                    .scaleEffect(isBreathing ? 0.92 : 1.0)
                    .opacity(isBreathing ? 0.7 : 1.0)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
            .contentShape(Circle())
            .onTapGesture { onTap?() }

            if let label {
                Text(label)
                    .font(.sora(11, weight: .light))
                    .foregroundColor(AuraTheme.textTertiary)
                    .tracking(0.5)
            }
        }
    }
}
