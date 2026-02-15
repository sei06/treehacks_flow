import SwiftUI

struct DemoProgressDots: View {
    let activeIndex: Int
    let total: Int = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                let scenario = demoScenarios[i]
                RoundedRectangle(cornerRadius: 99)
                    .fill(i <= activeIndex ? scenario.stressColor : AuraTheme.border)
                    .frame(width: i <= activeIndex ? 24 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: activeIndex)
            }
        }
    }
}
