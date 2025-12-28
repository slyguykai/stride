import SwiftUI
import SwiftData

struct WaitingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WaitingViewModel?
    @State private var selectedTask: Task?

    var body: some View {
        Group {
            if let viewModel, viewModel.waitingTasks.isEmpty {
                WaitingEmptyStateView()
            } else {
                List {
                    ForEach(viewModel?.waitingTasks ?? []) { task in
                        VStack(alignment: .leading, spacing: 8) {
                            TaskCard(task: task, size: .small) {
                                selectedTask = task
                            }
                            if let dueDate = viewModel?.followUpDate(for: task) {
                                Text("Next follow-up: \(dueDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Button("Copy follow-up message") {
                                viewModel?.followUpNow(task: task)
                            }
                            .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Waiting")
        .onAppear {
            if viewModel == nil {
                viewModel = WaitingViewModel(modelContext: modelContext)
            }
            viewModel?.load()
        }
        .refreshable {
            viewModel?.load()
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
        }
    }
}
