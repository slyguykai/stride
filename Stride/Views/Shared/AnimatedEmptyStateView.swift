import SwiftUI

/// Animated empty state view with floating icon and subtle motion
/// Replaces static empty states to add life and delight
struct AnimatedEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    @State private var isAnimating = false
    @State private var floatOffset: CGFloat = 0
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Floating animated icon
            ZStack {
                // Subtle glow behind icon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.15), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.secondary)
                    .offset(y: floatOffset)
                    .rotationEffect(.degrees(iconRotation))
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 10)
            
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(.blue.gradient)
                        )
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
        }
        .padding(32)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Entrance animation
        withAnimation(.strideSpringGentle.delay(0.1)) {
            isAnimating = true
        }
        
        // Continuous floating animation
        withAnimation(
            .easeInOut(duration: 3)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = -8
        }
        
        // Subtle rotation
        withAnimation(
            .easeInOut(duration: 6)
            .repeatForever(autoreverses: true)
        ) {
            iconRotation = 5
        }
    }
}

/// Specialized empty state for the Now view
struct NowEmptyStateView: View {
    let onCapture: () -> Void
    
    var body: some View {
        AnimatedEmptyStateView(
            icon: "checkmark.circle",
            title: "All clear",
            description: "You're all caught up! Capture a new thought to get started.",
            actionTitle: "Capture",
            action: onCapture
        )
    }
}

/// Specialized empty state for the Waiting view
struct WaitingEmptyStateView: View {
    var body: some View {
        AnimatedEmptyStateView(
            icon: "hourglass",
            title: "Nothing waiting",
            description: "Tasks waiting on others will appear here."
        )
    }
}

/// Specialized empty state for the Aspirational view
struct AspirationalEmptyStateView: View {
    var body: some View {
        AnimatedEmptyStateView(
            icon: "star",
            title: "Dream big",
            description: "Your aspirational goals will appear here when the time is right."
        )
    }
}

/// Specialized empty state for search/filter results
struct NoResultsEmptyStateView: View {
    let query: String
    
    var body: some View {
        AnimatedEmptyStateView(
            icon: "magnifyingglass",
            title: "No results",
            description: "Nothing matches \"\(query)\". Try a different search."
        )
    }
}

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 60) {
            NowEmptyStateView(onCapture: {})
            WaitingEmptyStateView()
            AspirationalEmptyStateView()
            NoResultsEmptyStateView(query: "test")
        }
    }
}

