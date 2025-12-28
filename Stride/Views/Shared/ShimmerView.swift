import SwiftUI

/// Shimmering loading placeholder view for skeleton states
/// Use when content is loading to maintain layout and reduce perceived latency
struct ShimmerView: View {
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemGray5),
                Color(.systemGray4),
                Color(.systemGray5)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(Rectangle())
        .offset(x: isAnimating ? 200 : -200)
        .animation(
            .linear(duration: 1.5)
            .repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Skeleton placeholder for a task card while loading
struct TaskCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            // Energy indicator
            ShimmerView()
                .frame(width: 4, height: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                ShimmerView()
                    .frame(height: 16)
                    .frame(maxWidth: 200)
                
                // Subtitle
                ShimmerView()
                    .frame(height: 12)
                    .frame(maxWidth: 140)
            }
            
            Spacer()
            
            // Progress ring placeholder
            ShimmerView()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Skeleton placeholder for parsed task preview
struct ParsedTaskSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title section
            VStack(alignment: .leading, spacing: 8) {
                ShimmerView()
                    .frame(height: 20)
                    .frame(maxWidth: 250)
                
                HStack(spacing: 12) {
                    ShimmerView()
                        .frame(width: 60, height: 14)
                    
                    ShimmerView()
                        .frame(width: 80, height: 14)
                }
            }
            
            // Subtasks section
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    HStack(spacing: 12) {
                        ShimmerView()
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        
                        ShimmerView()
                            .frame(height: 14)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview("Shimmer") {
    VStack(spacing: 20) {
        ShimmerView()
            .frame(height: 20)
            .frame(maxWidth: 200)
        
        TaskCardSkeleton()
        
        ParsedTaskSkeleton()
    }
    .padding()
}

