import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let task: Task
    @State private var viewModel: TaskDetailViewModel?

    init(task: Task) {
        self.task = task
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                originalThought
                subtasksSection
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel = TaskDetailViewModel(task: task, modelContext: modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Mark Waiting") { viewModel?.markWaiting() }
                    Button("Delete", role: .destructive) {
                        viewModel?.delete()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.title2.bold())

                HStack(spacing: 16) {
                    Label("\(task.estimatedMinutes) min", systemImage: "clock")
                    Label(task.energyLevel.title, systemImage: "bolt.fill")
                        .foregroundStyle(task.energyLevel.color)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()

            ProgressRing(progress: task.progress)
                .frame(width: 56, height: 56)
        }
    }

    private var originalThought: some View {
        DisclosureGroup("Original thought") {
            Text(task.rawInput)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .tint(.secondary)
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps")
                .font(.headline)

            ForEach(task.subtasks.sorted(by: { $0.order < $1.order })) { subtask in
                SubtaskRow(subtask: subtask) {
                    _Concurrency.Task { await viewModel?.toggleSubtask(subtask) }
                }
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)

            LabeledContent("Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Deferred", value: "\(task.deferCount) times")
            LabeledContent("Status", value: task.status.rawValue.capitalized)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

struct SubtaskRow: View {
    let subtask: Subtask
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(subtask.isCompleted ? .green : .secondary)
                    .font(.title3)

                Text(subtask.title)
                    .strikethrough(subtask.isCompleted)
                    .foregroundStyle(subtask.isCompleted ? .secondary : .primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
