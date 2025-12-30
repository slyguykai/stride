import SwiftUI

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 4
    var backgroundColor: Color = .secondary.opacity(0.2)
    var foregroundColor: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
    }
}
