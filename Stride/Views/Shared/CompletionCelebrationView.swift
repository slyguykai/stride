import SwiftUI

struct CompletionCelebrationView: View {
    let title: String

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ParticleBurst(isAnimating: isAnimating)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1 : 0)
                    .animation(Animation.strideSpringBouncy, value: isAnimating)
            }

            Text("Nice!")
                .font(.title2.bold())
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 12)
        .onAppear {
            isAnimating = true
        }
    }
}

struct ParticleBurst: View {
    let isAnimating: Bool
    private let particleCount = 12

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(particleColor(for: index))
                    .frame(width: 8, height: 8)
                    .offset(particleOffset(for: index))
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0.5 : 1)
                    .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.02), value: isAnimating)
            }
        }
    }

    private func particleOffset(for index: Int) -> CGSize {
        let angle = (2 * Double.pi / Double(particleCount)) * Double(index)
        let distance: CGFloat = isAnimating ? 60 : 0
        return CGSize(
            width: CGFloat(cos(angle)) * distance,
            height: CGFloat(sin(angle)) * distance
        )
    }

    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .yellow, .blue, .orange]
        return colors[index % colors.count]
    }
}
