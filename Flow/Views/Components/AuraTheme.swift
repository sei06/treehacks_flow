import SwiftUI

struct AuraTheme {
    // Backgrounds
    static let bg = Color(red: 0.957, green: 0.961, blue: 0.969)           // #f4f5f7
    static let surface = Color.white                                         // #ffffff
    static let well = Color(red: 0.925, green: 0.933, blue: 0.949)         // #eceef2
    static let border = Color(red: 0.867, green: 0.878, blue: 0.902)       // #dde0e6

    // Text
    static let textPrimary = Color(red: 0.118, green: 0.125, blue: 0.157)  // #1e2028
    static let textSecondary = Color(red: 0.431, green: 0.447, blue: 0.502) // #6e7280
    static let textTertiary = Color(red: 0.643, green: 0.659, blue: 0.706) // #a4a8b4

    // Accent
    static let accent = Color(red: 0.353, green: 0.478, blue: 0.588)       // #5a7a96
    static let accentMuted = Color(red: 0.282, green: 0.416, blue: 0.518)  // #486a84

    // Stress states
    static let stressHigh = Color(red: 0.753, green: 0.376, blue: 0.345)   // #c06058
    static let stressMed = Color(red: 0.753, green: 0.596, blue: 0.376)    // #c09860
    static let stressLow = Color(red: 0.353, green: 0.541, blue: 0.471)    // #5a8a78

    // Shadows
    static let cardShadow = Color.black.opacity(0.04)
    static let artShadow = Color(red: 0.353, green: 0.478, blue: 0.588).opacity(0.12)

    // Helper: stress color from level string
    static func stressColor(for level: String) -> Color {
        switch level {
        case "high": return stressHigh
        case "moderate": return stressMed
        case "low": return stressLow
        default: return accent
        }
    }
}

// MARK: - StressLevel → Color

extension StressLevel {
    var themeColor: Color {
        switch self {
        case .high: return AuraTheme.stressHigh
        case .moderate: return AuraTheme.stressMed
        case .low: return AuraTheme.stressLow
        }
    }
}

// MARK: - Sora + JetBrains Mono Font Helpers

extension Font {
    static func sora(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let weightName: String = switch weight {
        case .ultraLight, .thin, .light: "Sora-Light"
        case .regular: "Sora-Regular"
        case .medium: "Sora-Medium"
        case .semibold: "Sora-SemiBold"
        case .bold, .heavy, .black: "Sora-Bold"
        default: "Sora-Regular"
        }
        return .custom(weightName, size: size)
    }

    static func mono(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", size: size)
    }

    static func monoMedium(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: size)
    }
}

// MARK: - Legacy font helpers (used by existing screens)

enum AuraFont {
    static func brand(_ size: CGFloat) -> Font {
        .custom("Sora-Light", size: size)
    }
    static func data(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", size: size)
    }
}

// MARK: - Aura Card Modifier

struct AuraCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AuraTheme.surface)
            )
            .shadow(color: AuraTheme.cardShadow, radius: 3, x: 0, y: 1)
    }
}

extension View {
    func auraCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(AuraCardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.12), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 300)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
