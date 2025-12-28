import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let task: Task
    @State private var viewModel: TaskDetailViewModel?
    @State private var showRecurringEditor = false
    @State private var showWaitingConfig = false

    init(task: Task) {
        self.task = task
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                originalThought
                subtasksSection
                recurringSection
                aspirationalSection
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
                    Button("Mark Waiting") {
                        showWaitingConfig = true
                    }
                    Button("Recurring Rule") { showRecurringEditor = true }
                    Button("Delete", role: .destructive) {
                        viewModel?.delete()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showRecurringEditor) {
            RecurringRuleEditorView(task: task)
        }
        .sheet(isPresented: $showWaitingConfig) {
            WaitingConfigView(task: task)
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
            if let deferUntil = task.deferUntil {
                LabeledContent("Deferred until", value: deferUntil.formatted(date: .abbreviated, time: .shortened))
            }
            if task.status == .waiting {
                LabeledContent("Waiting since", value: (task.waitingSince ?? task.createdAt).formatted(date: .abbreviated, time: .shortened))
                if let contact = task.waitingContactName, !contact.isEmpty {
                    LabeledContent("Waiting on", value: contact)
                }
                if let interval = task.waitingFollowUpIntervalDays {
                    LabeledContent("Follow up every", value: "\(interval) days")
                }
            }
            LabeledContent("Status", value: task.status.rawValue.capitalized)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recurring")
                    .font(.headline)
                Spacer()
                Button(task.recurringRule == nil ? "Add" : "Edit") {
                    showRecurringEditor = true
                }
                .font(.subheadline)
            }

            if let rule = task.recurringRule {
                RecurringWindowView(rule: rule)
            } else {
                Text("No recurring rule set.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var aspirationalSection: some View {
        if task.taskType == .aspirational {
            VStack(alignment: .leading, spacing: 8) {
                Text("Aspirational notes")
                    .font(.headline)
                if let why = task.aspirationWhy, !why.isEmpty {
                    Text("Why: \(why)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let when = task.aspirationWhen, !when.isEmpty {
                    Text("When: \(when)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if task.aspirationOnboardingComplete ?? false == false {
                    Text("Answer the prompts in Aspirational to add context.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
