import SwiftUI
import SwiftData

struct AspirationalView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var tasks: [Task] = []
    @State private var showCapture = false
    @State private var selectedTask: Task?
    @State private var onboardingTask: Task?

    var body: some View {
        Group {
            if tasks.isEmpty {
                AspirationalEmptyStateView()
            } else {
                List {
                    ForEach(tasks) { task in
                        VStack(alignment: .leading, spacing: 8) {
                            TaskCard(task: task, size: .small) {
                                selectedTask = task
                            }
                            if task.aspirationOnboardingComplete ?? false == false {
                                Button("Answer a few prompts") {
                                    onboardingTask = task
                                }
                                .font(.subheadline)
                            }
                            if let why = task.aspirationWhy, !why.isEmpty {
                                Text("Why: \(why)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let when = task.aspirationWhen, !when.isEmpty {
                                Text("When: \(when)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Aspirational")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCapture = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .onAppear { load() }
        .refreshable { load() }
        .sheet(isPresented: $showCapture) {
            AspirationalCaptureView()
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
        .sheet(item: $onboardingTask) { task in
            AspirationalOnboardingView(task: task)
        }
    }

    private func load() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
        )
        let allTasks = (try? modelContext.fetch(descriptor)) ?? []
        tasks = allTasks.filter { $0.taskType == .aspirational }
    }
}
