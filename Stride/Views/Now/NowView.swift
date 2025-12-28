import SwiftUI
import SwiftData

struct NowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NowViewModel?
    @State private var showCapture = false

    var body: some View {
        Group {
            if let viewModel, viewModel.tasks.isEmpty {
                ContentUnavailableView(
                    "No tasks yet",
                    systemImage: "checkmark.circle",
                    description: Text("Capture your first thought to get started.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel?.tasks ?? []) { task in
                            SwipeableCard {
                                TaskCard(task: task, size: viewModel?.cardSize(for: task) ?? .medium) {
                                    viewModel?.selectedTask = task
                                }
                            } onSwipeRight: {
                                await viewModel?.complete(task)
                            } onSwipeLeft: {
                                viewModel?.showDefer(task)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding()
                }
                .animation(.spring(), value: viewModel?.tasks.count ?? 0)
            }
        }
        .navigationTitle("Now")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCapture = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .accessibilityLabel("Capture")
            }
        }
        .sheet(isPresented: $showCapture) {
            NavigationStack {
                CaptureView()
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showDeferSheet ?? false },
            set: { viewModel?.showDeferSheet = $0 }
        )) {
            if let task = viewModel?.taskToDefer {
                DeferPlaceholderSheet(task: task) { reason in
                    viewModel?.deferTask(task, reason: reason)
                }
            }
        }
        .navigationDestination(item: Binding(
            get: { viewModel?.selectedTask },
            set: { viewModel?.selectedTask = $0 }
        )) { task in
            TaskDetailView(task: task)
        }
        .task {
            SampleDataSeeder.seedIfNeeded(modelContext: modelContext)
            if viewModel == nil {
                viewModel = NowViewModel(modelContext: modelContext)
            }
            viewModel?.loadTasks()
        }
    }
}

struct DeferPlaceholderSheet: View {
    let task: Task
    let onDefer: (DeferReason) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Why are you deferring?")
                    .font(.headline)

                ForEach(DeferReason.allCases, id: \.self) { reason in
                    Button {
                        onDefer(reason)
                        dismiss()
                    } label: {
                        HStack {
                            Text(reason.title)
                            Spacer()
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .navigationTitle("Defer Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        NowView()
    }
}
