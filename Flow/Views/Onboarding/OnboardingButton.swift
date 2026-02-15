import SwiftUI

struct OnboardingButton: View {
    let label: String
    var isSecondary: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.sora(15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isSecondary ? AuraTheme.well :
                    disabled ? AuraTheme.well :
                    AuraTheme.accent
                )
                .foregroundColor(
                    isSecondary ? AuraTheme.textSecondary :
                    disabled ? AuraTheme.textTertiary :
                    .white
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(
                    color: isSecondary || disabled ? .clear : AuraTheme.accent.opacity(0.15),
                    radius: 16, y: 4
                )
        }
        .disabled(disabled)
    }
}
