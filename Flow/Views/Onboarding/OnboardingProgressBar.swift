import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                RoundedRectangle(cornerRadius: 99)
                    .fill(i <= currentStep ? AuraTheme.accent : AuraTheme.border)
                    .opacity(i < currentStep ? 0.5 : i == currentStep ? 1 : 0.4)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 24)
    }
}
