import SwiftUI

struct TaskCard: View {
    let task: Task
    var size: TaskCardSize = .medium
    var onTap: (() -> Void)?

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
    }

    var body: some View {
        HStack(spacing: 12) {
            energyIndicator

            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.headline)

                if let firstSubtask = task.subtasks.first(where: { !$0.isCompleted }) {
                    Text(firstSubtask.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if task.subtasks.count > 1 {
                ProgressRing(progress: task.progress)
                    .frame(width: 36, height: 36)
            }

            contextIcons
        }
        .padding(Layout.padding * size.paddingScale)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .scaleEffect(size.scale)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view details. Swipe right to complete. Swipe left to defer.")
        .accessibilityAddTraits(.isButton)
    }

    private var energyIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(task.energyLevel.color)
            .frame(width: 4)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color(.secondarySystemBackground))
    }

    @ViewBuilder
    private var contextIcons: some View {
        HStack(spacing: 6) {
            if task.status == .waiting {
                Image(systemName: "hourglass")
                    .foregroundStyle(.orange)
            }
            if task.estimatedMinutes <= 5 {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .font(.caption)
    }

    private var accessibilityLabel: String {
        var label = task.title
        label += ". \(task.energyLevel.title)."
        label += " Estimated \(task.estimatedMinutes) minutes."
        if task.subtasks.count > 1 {
            let completed = task.subtasks.filter(\Subtask.isCompleted).count
            label += " \(completed) of \(task.subtasks.count) steps completed."
        }
        return label
    }
}

enum TaskCardSize {
    case large
    case medium
    case small

    var scale: CGFloat {
        switch self {
        case .large: return 1.02
        case .medium: return 1.0
        case .small: return 0.96
        }
    }

    var paddingScale: CGFloat {
        switch self {
        case .large: return 1.1
        case .medium: return 1.0
        case .small: return 0.85
        }
    }
}
