import SwiftUI
import SwiftData

struct NowView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NowViewModel?
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var showInsights = false
    @State private var showCompletionCelebration = false
    @State private var showCascadeBanner = false

    var body: some View {
        contentView
        .navigationTitle("Now")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showCapture) {
            NavigationStack {
                CaptureView()
            }
        }
        .sheet(isPresented: deferSheetBinding) { deferSheetContent }
        .sheet(item: focusTimeBinding) { candidate in
            FocusTimeView(candidate: candidate, modelContext: modelContext)
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showInsights) {
            NavigationStack {
                PatternInsightsView()
            }
        }
        .navigationDestination(item: selectedTaskBinding) { task in
            TaskDetailView(task: task)
        }
        .task {
            SampleDataSeeder.seedIfNeeded(modelContext: modelContext)
            if viewModel == nil {
                viewModel = NowViewModel(modelContext: modelContext)
            }
            viewModel?.loadTasks()
            RetrospectiveScheduler().scheduleWeekly()
        }
        .overlay {
            if showCompletionCelebration, let title = viewModel?.lastCompletionTitle {
                CompletionCelebrationView(title: title)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onChange(of: viewModel?.lastCompletionTitle) { _, newValue in
            guard newValue != nil else { return }
            showCompletionCelebration = true
            withAnimation(.spring()) {
                showCascadeBanner = (viewModel?.cascadeCount ?? 0) > 0
            }
            _Concurrency.Task {
                try? await _Concurrency.Task.sleep(for: .seconds(1.4))
                withAnimation(.spring()) {
                    showCompletionCelebration = false
                    showCascadeBanner = false
                }
                viewModel?.lastCompletionTitle = nil
                viewModel?.cascadeCount = nil
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if let viewModel, viewModel.tasks.isEmpty {
            NowEmptyStateView {
                showCapture = true
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            taskListView
        }
    }

    private var taskListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                streakSummaryView
                cascadeBannerView
                tasksListView
                aspirationalSectionView
            }
            .padding()
        }
        .animation(.strideSpring, value: viewModel?.tasks.count ?? 0)
    }

    @ViewBuilder
    private var streakSummaryView: some View {
        if let streak = viewModel?.streakData {
            StreakSummaryView(data: streak)
        }
    }

    @ViewBuilder
    private var cascadeBannerView: some View {
        if let count = viewModel?.cascadeCount, count > 0, showCascadeBanner {
            CascadeBannerView(count: count)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private var tasksListView: some View {
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

    @ViewBuilder
    private var aspirationalSectionView: some View {
        if viewModel?.showAspirationalSection == true {
            AspirationalSectionView(tasks: viewModel?.aspirationalTasks ?? []) { task in
                viewModel?.selectedTask = task
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button("Insights") {
                    showInsights = true
                }
                Button("Settings") {
                    showSettings = true
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .accessibilityLabel("More")
        }
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

    private var deferSheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel?.showDeferSheet ?? false },
            set: { viewModel?.showDeferSheet = $0 }
        )
    }

    private var selectedTaskBinding: Binding<Task?> {
        Binding(
            get: { viewModel?.selectedTask },
            set: { viewModel?.selectedTask = $0 }
        )
    }

    private var focusTimeBinding: Binding<FocusTimeCandidate?> {
        Binding(
            get: { viewModel?.focusTimeCandidate },
            set: { viewModel?.focusTimeCandidate = $0 }
        )
    }

    @ViewBuilder
    private var deferSheetContent: some View {
        if let task = viewModel?.taskToDefer {
            DeferSheet(task: task) { reason, time in
                await viewModel?.deferTask(task, reason: reason, until: time)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NowView()
    }
}
