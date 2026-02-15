import SwiftUI

struct AudioBars: View {
    let color: Color
    private let barCount = 5
    private let heights: [CGFloat] = [12, 18, 8, 15, 10]

    var body: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(0..<barCount, id: \.self) { i in
                PulsingBar(height: heights[i], color: color, delay: Double(i) * 0.15)
            }
        }
        .frame(height: 18)
    }
}

private struct PulsingBar: View {
    let height: CGFloat
    let color: Color
    let delay: Double
    @State private var isPulsing = false

    var body: some View {
        RoundedRectangle(cornerRadius: 99)
            .fill(color)
            .frame(width: 3, height: isPulsing ? height : height * 0.4)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4 + delay).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}
