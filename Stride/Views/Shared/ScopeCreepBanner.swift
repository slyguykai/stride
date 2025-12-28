import SwiftUI

/// Animated banner that appears when scope creep is detected during task editing
struct ScopeCreepBanner: View {
    let result: ScopeCreepResult
    let onKeep: () -> Void
    let onSplit: () -> Void
    let onRevert: () -> Void
    
    @State private var isExpanded = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed banner
            HStack(spacing: 12) {
                pulsingIndicator
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Task expanding")
                        .font(.subheadline.bold())
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded options
            if isExpanded {
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Text(suggestionMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "Keep",
                            subtitle: "Accept changes",
                            systemImage: "checkmark.circle",
                            color: .green
                        ) {
                            onKeep()
                        }
                        
                        ActionButton(
                            title: "Split",
                            subtitle: "New task",
                            systemImage: "arrow.triangle.branch",
                            color: .blue
                        ) {
                            onSplit()
                        }
                        
                        ActionButton(
                            title: "Revert",
                            subtitle: "Undo",
                            systemImage: "arrow.uturn.backward",
                            color: .orange
                        ) {
                            onRevert()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(backgroundGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warningColor.opacity(0.2), radius: 8, y: 4)
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private var pulsingIndicator: some View {
        ZStack {
            Circle()
                .fill(warningColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .scaleEffect(pulseScale)
            
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(warningColor)
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                warningColor.opacity(0.08),
                warningColor.opacity(0.04)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var warningColor: Color {
        switch result.severity {
        case .mild:
            return .yellow
        case .moderate:
            return .orange
        case .severe:
            return .red
        }
    }
    
    private var suggestionMessage: String {
        switch result.severity {
        case .mild:
            return "Minor expansion detected. You can keep going or split later."
        case .moderate:
            return "This task is growing. Consider splitting to stay focused."
        case .severe:
            return "Significant scope increase. Splitting is recommended to maintain momentum."
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.15
        }
    }
}

private struct ActionButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.caption.bold())
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        ScopeCreepBanner(
            result: ScopeCreepResult(
                addedMinutes: 25,
                addedSubtasks: 3,
                addedDependencies: 1,
                descriptionExpansion: 100,
                suggestion: .split,
                severity: .moderate
            ),
            onKeep: {},
            onSplit: {},
            onRevert: {}
        )
        
        ScopeCreepBanner(
            result: ScopeCreepResult(
                addedMinutes: 45,
                addedSubtasks: 5,
                addedDependencies: 2,
                descriptionExpansion: 300,
                suggestion: .split,
                severity: .severe
            ),
            onKeep: {},
            onSplit: {},
            onRevert: {}
        )
    }
    .padding()
}

