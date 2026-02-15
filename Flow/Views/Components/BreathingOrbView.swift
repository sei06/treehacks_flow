import SwiftUI

struct BreathingOrbView: View {
    let color: Color
    var size: CGFloat = 120
    var isDisabled: Bool = false
    let action: () -> Void

    @State private var isBreathing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.09),
                                color.opacity(0.03),
                                Color.clear,
                            ],
                            center: UnitPoint(x: 0.4, y: 0.38),
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )
                    .frame(width: size, height: size)
                    .scaleEffect(isBreathing ? 1.06 : 1.0)
                    .opacity(isBreathing ? 0.7 : 1.0)

                // Middle ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.07),
                                Color.clear,
                            ],
                            center: UnitPoint(x: 0.45, y: 0.4),
                            startRadius: 0,
                            endRadius: size * 0.35
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.13), lineWidth: 1.5)
                    )
                    .frame(width: size * 0.7, height: size * 0.7)
                    .scaleEffect(isBreathing ? 1.06 : 1.0)
                    .opacity(isBreathing ? 0.7 : 1.0)
                    .animation(
                        .easeInOut(duration: 4).repeatForever(autoreverses: true).delay(0.5),
                        value: isBreathing
                    )

                // Inner ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.06),
                                Color.clear,
                            ],
                            center: UnitPoint(x: 0.45, y: 0.4),
                            startRadius: 0,
                            endRadius: size * 0.22
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(color.opacity(0.09), lineWidth: 1)
                    )
                    .frame(width: size * 0.34, height: size * 0.34)

                // Center content
                VStack(spacing: 2) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AuraTheme.accent)
                    Text("compose")
                        .font(AuraFont.brand(12))
                        .foregroundColor(AuraTheme.accent)
                }
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
        .animation(
            .easeInOut(duration: 4).repeatForever(autoreverses: true),
            value: isBreathing
        )
        .onAppear {
            isBreathing = true
        }
    }
}
