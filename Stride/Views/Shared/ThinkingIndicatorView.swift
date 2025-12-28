import SwiftUI

/// Animated "AI thinking" indicator with floating orbs and subtle motion
/// Provides visual feedback during AI processing without being distracting
struct ThinkingIndicatorView: View {
    @State private var isAnimating = false
    @State private var orbPhases: [Double] = [0, 0.33, 0.66]
    
    private let orbCount = 3
    private let orbSize: CGFloat = 10
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated orbs
            HStack(spacing: 8) {
                ForEach(0..<orbCount, id: \.self) { index in
                    Circle()
                        .fill(orbGradient)
                        .frame(width: orbSize, height: orbSize)
                        .scaleEffect(isAnimating ? 1.0 : 0.6)
                        .opacity(isAnimating ? 1.0 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            // Thinking text with typing effect
            ThinkingTextView()
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var orbGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Animated text that cycles through thinking phrases
private struct ThinkingTextView: View {
    @State private var currentPhrase = 0
    @State private var opacity: Double = 1.0
    
    private let phrases = [
        "Understanding your thought...",
        "Breaking it down...",
        "Finding the next steps..."
    ]
    
    var body: some View {
        Text(phrases[currentPhrase])
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.3), value: opacity)
            .task {
                await cyclePhrase()
            }
    }
    
    private func cyclePhrase() async {
        while !_Concurrency.Task<Never, Never>.isCancelled {
            try? await _Concurrency.Task.sleep(for: .seconds(2))
            
            withAnimation {
                opacity = 0
            }
            
            try? await _Concurrency.Task.sleep(for: .milliseconds(300))
            
            currentPhrase = (currentPhrase + 1) % phrases.count
            
            withAnimation {
                opacity = 1
            }
        }
    }
}

/// Full-screen thinking overlay with background blur
struct ThinkingOverlayView: View {
    let isShowing: Bool
    
    var body: some View {
        ZStack {
            if isShowing {
                Color.black.opacity(0.1)
                    .ignoresSafeArea()
                    .transition(.opacity)
                
                ThinkingIndicatorView()
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Animation.strideSpringGentle, value: isShowing)
    }
}

/// Inline thinking indicator for compact spaces
struct InlineThinkingIndicator: View {
    @State private var dotIndex = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .foregroundStyle(.blue)
                .symbolEffect(.pulse)
            
            Text("Thinking")
                .foregroundStyle(.secondary)
            
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 4, height: 4)
                        .opacity(index <= dotIndex ? 1 : 0.3)
                }
            }
        }
        .font(.caption)
        .task {
            await animateDots()
        }
    }
    
    private func animateDots() async {
        while !_Concurrency.Task<Never, Never>.isCancelled {
            try? await _Concurrency.Task.sleep(for: .milliseconds(300))
            dotIndex = (dotIndex + 1) % 4
            if dotIndex == 3 {
                dotIndex = -1
            }
        }
    }
}

#Preview("Thinking Indicator") {
    VStack(spacing: 40) {
        ThinkingIndicatorView()
        
        InlineThinkingIndicator()
    }
    .padding()
}

#Preview("Thinking Overlay") {
    ZStack {
        Color.gray.opacity(0.2)
        Text("Content behind")
        
        ThinkingOverlayView(isShowing: true)
    }
}

