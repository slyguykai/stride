# iOS Developer Agent

> Feature implementation, UI components, and SwiftUI view development for the Stride iOS app.

---

## Role Summary

You are an **iOS Developer** for Stride. Your responsibilities include:

- Building SwiftUI views and components
- Implementing view models for features
- Adding gestures and interactions
- Integrating with services and engines
- Following established patterns from iOS Lead

---

## When This Agent Applies

Consult this file when working on:

- New screens or views (Phases 2-7)
- UI components (TaskCard, ProgressRing, etc.)
- View models for features
- Gesture implementations
- Feature-specific business logic
- Integration with existing services

---

## SwiftUI Patterns

### View Structure

```swift
import SwiftUI

struct NowView: View {
    // MARK: - State
    @State private var viewModel: NowViewModel
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Init
    init(viewModel: NowViewModel = NowViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        content
            .task { await viewModel.loadTasks() }
            .refreshable { await viewModel.refreshTasks() }
    }
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            loadingView
        } else if viewModel.tasks.isEmpty {
            emptyView
        } else {
            taskList
        }
    }
    
    // MARK: - Subviews
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No tasks yet",
            systemImage: "checkmark.circle",
            description: Text("Capture your first thought to get started")
        )
    }
    
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.tasks) { task in
                    TaskCard(task: task)
                        .onSwipeComplete { await viewModel.complete(task) }
                        .onSwipeDefer { viewModel.showDefer(task) }
                }
            }
            .padding()
        }
    }
}
```

### Component Design

```swift
struct TaskCard: View {
    // MARK: - Properties
    let task: Task
    var onTap: (() -> Void)?
    var onComplete: (() async -> Void)?
    var onDefer: (() -> Void)?
    
    // MARK: - State
    @State private var offset: CGFloat = 0
    @State private var isPressed = false
    
    // MARK: - Constants
    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let swipeThreshold: CGFloat = 100
    }
    
    // MARK: - Body
    var body: some View {
        cardContent
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            .offset(x: offset)
            .gesture(swipeGesture)
            .scaleEffect(isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3), value: isPressed)
            .onTapGesture { onTap?() }
            .onLongPressGesture(
                minimumDuration: 0.1,
                pressing: { isPressed = $0 },
                perform: {}
            )
    }
    
    // MARK: - Card Content
    private var cardContent: some View {
        HStack(spacing: 12) {
            energyIndicator
            
            VStack(alignment: .leading, spacing: 4) {
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
                    .frame(width: 32, height: 32)
            }
            
            contextIcons
        }
        .padding(Layout.padding)
    }
    
    // MARK: - Supporting Views
    private var energyIndicator: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(task.energyLevel.color)
            .frame(width: 4, height: 40)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(.background)
    }
    
    @ViewBuilder
    private var contextIcons: some View {
        HStack(spacing: 4) {
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
    
    // MARK: - Gestures
    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                if value.translation.width > Layout.swipeThreshold {
                    // Complete
                    Task { await onComplete?() }
                } else if value.translation.width < -Layout.swipeThreshold {
                    // Defer
                    onDefer?()
                }
                withAnimation(.spring()) {
                    offset = 0
                }
            }
    }
}

// MARK: - Preview
#Preview {
    TaskCard(task: .preview)
        .padding()
}
```

---

## ViewModel Pattern

```swift
import SwiftUI
import SwiftData

@Observable
@MainActor
final class NowViewModel {
    // MARK: - Dependencies
    private let taskService: TaskServiceProtocol
    private let contextEngine: ContextEngineProtocol
    
    // MARK: - State
    private(set) var tasks: [Task] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    // MARK: - UI State
    var selectedTask: Task?
    var showDeferSheet = false
    var taskToDefer: Task?
    
    // MARK: - Init
    init(
        taskService: TaskServiceProtocol = DependencyContainer.shared.taskService,
        contextEngine: ContextEngineProtocol = DependencyContainer.shared.contextEngine
    ) {
        self.taskService = taskService
        self.contextEngine = contextEngine
    }
    
    // MARK: - Actions
    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let allTasks = try await taskService.fetchActiveTasks()
            self.tasks = await contextEngine.rankTasks(allTasks).prefix(5).map { $0 }
        } catch {
            self.error = error
        }
    }
    
    func refreshTasks() async {
        // Don't show loading indicator for refresh
        do {
            let allTasks = try await taskService.fetchActiveTasks()
            self.tasks = await contextEngine.rankTasks(allTasks).prefix(5).map { $0 }
        } catch {
            self.error = error
        }
    }
    
    func complete(_ task: Task) async {
        do {
            try await taskService.complete(task)
            // Remove from local list with animation
            withAnimation {
                tasks.removeAll { $0.id == task.id }
            }
            // Reload to get newly unblocked tasks
            await loadTasks()
        } catch {
            self.error = error
        }
    }
    
    func showDefer(_ task: Task) {
        taskToDefer = task
        showDeferSheet = true
    }
    
    func defer(_ task: Task, reason: DeferReason, until: Date?) async {
        do {
            try await taskService.defer(task, reason: reason, until: until)
            withAnimation {
                tasks.removeAll { $0.id == task.id }
            }
        } catch {
            self.error = error
        }
        showDeferSheet = false
        taskToDefer = nil
    }
}
```

---

## Feature Implementation Guides

### Capture Screen (Phase 2)

```swift
struct CaptureView: View {
    @State private var viewModel = CaptureViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Raw input display (preserves original thought)
            if !viewModel.rawInput.isEmpty {
                rawInputSection
            }
            
            Spacer()
            
            // AI processing state
            if viewModel.isProcessing {
                processingView
            }
            
            // AI suggestions (editable)
            if let parsed = viewModel.parsedTask {
                ParsedTaskEditor(parsed: parsed) { edited in
                    viewModel.acceptTask(edited)
                }
            }
            
            Spacer()
            
            // Input area
            inputArea
        }
        .onAppear { isInputFocused = true }
    }
    
    private var rawInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your thought")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(viewModel.rawInput)
                .font(.body)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    
    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Understanding your thought...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("What's on your mind?", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .lineLimit(1...5)
            
            // Voice input button
            Button {
                viewModel.startVoiceCapture()
            } label: {
                Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                    .font(.title2)
                    .symbolEffect(.pulse, isActive: viewModel.isRecording)
            }
            
            // Submit button
            Button {
                Task { await viewModel.submit() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(viewModel.input.isEmpty)
        }
        .padding()
        .background(.bar)
    }
}
```

### Defer Sheet (Phase 4)

```swift
struct DeferSheet: View {
    let task: Task
    let onDefer: (DeferReason, Date?) async -> Void
    
    @State private var selectedReason: DeferReason?
    @State private var selectedTime: Date?
    @State private var showTimePicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Task preview
                TaskCard(task: task)
                    .disabled(true)
                
                // Reason buttons
                reasonButtons
                
                // Time options (shown after reason selected)
                if selectedReason != nil {
                    timeOptions
                }
                
                Spacer()
                
                // Confirm button
                if selectedReason != nil {
                    confirmButton
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
        .presentationDetents([.medium, .large])
    }
    
    private var reasonButtons: some View {
        VStack(spacing: 12) {
            Text("Why are you deferring?")
                .font(.headline)
            
            ForEach(DeferReason.allCases, id: \.self) { reason in
                Button {
                    withAnimation { selectedReason = reason }
                } label: {
                    HStack {
                        Text(reason.emoji)
                        Text(reason.title)
                        Spacer()
                        if selectedReason == reason {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding()
                    .background(selectedReason == reason ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var timeOptions: some View {
        VStack(spacing: 12) {
            Text("Remind me")
                .font(.headline)
            
            HStack(spacing: 12) {
                TimeOptionButton(title: "1 hour", time: .now.addingTimeInterval(3600)) {
                    selectedTime = $0
                }
                TimeOptionButton(title: "Tonight", time: todayAt(hour: 19)) {
                    selectedTime = $0
                }
                TimeOptionButton(title: "Tomorrow", time: tomorrowMorning()) {
                    selectedTime = $0
                }
                TimeOptionButton(title: "Pick...", time: nil) {
                    showTimePicker = true
                }
            }
        }
        .sheet(isPresented: $showTimePicker) {
            DatePicker("Select time", selection: Binding(
                get: { selectedTime ?? .now },
                set: { selectedTime = $0 }
            ), in: Date.now...)
                .datePickerStyle(.graphical)
                .presentationDetents([.medium])
        }
    }
    
    private var confirmButton: some View {
        Button {
            Task {
                await onDefer(selectedReason!, selectedTime)
                dismiss()
            }
        } label: {
            Text("Defer")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // Helper functions
    private func todayAt(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
    }
    
    private func tomorrowMorning() -> Date {
        Calendar.current.date(byAdding: .day, value: 1, to: todayAt(hour: 9)) ?? .now
    }
}
```

### Task Detail View

```swift
struct TaskDetailView: View {
    let task: Task
    @State private var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(task: Task) {
        self.task = task
        _viewModel = State(initialValue: TaskDetailViewModel(task: task))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with energy indicator
                header
                
                // Original thought (collapsible)
                originalThought
                
                // Subtasks
                subtasksSection
                
                // Dependencies
                if !viewModel.blockers.isEmpty {
                    dependenciesSection
                }
                
                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Edit") { viewModel.startEditing() }
                    Button("Mark Waiting") { viewModel.markWaiting() }
                    Button("Delete", role: .destructive) { viewModel.delete() }
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
                    Task { await viewModel.toggleSubtask(subtask) }
                }
            }
        }
    }
    
    private var dependenciesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blocked by")
                .font(.headline)
            
            ForEach(viewModel.blockers) { blocker in
                HStack {
                    Image(systemName: "arrow.turn.down.right")
                        .foregroundStyle(.orange)
                    Text(blocker.title)
                }
                .font(.subheadline)
            }
        }
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.headline)
            
            LabeledContent("Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Deferred", value: "\(task.deferCount) times")
            LabeledContent("Status", value: task.status.title)
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
```

---

## Reusable Components

### Progress Ring

```swift
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 4
    var backgroundColor: Color = .secondary.opacity(0.2)
    var foregroundColor: Color = .accentColor
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        }
    }
}
```

### Energy Level Extension

```swift
extension EnergyLevel {
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
    
    var title: String {
        switch self {
        case .low: return "Low energy"
        case .medium: return "Medium energy"
        case .high: return "High energy"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "bolt"
        case .medium: return "bolt.fill"
        case .high: return "bolt.trianglebadge.exclamationmark.fill"
        }
    }
}
```

### Defer Reason Extension

```swift
extension DeferReason {
    var emoji: String {
        switch self {
        case .blocked: return "🚫"
        case .noEnergy: return "😴"
        case .wrongTime: return "⏰"
        case .unsure: return "🤔"
        case .notImportant: return "🤷"
        }
    }
    
    var title: String {
        switch self {
        case .blocked: return "Blocked by something"
        case .noEnergy: return "No energy right now"
        case .wrongTime: return "Wrong time"
        case .unsure: return "Unsure how to start"
        case .notImportant: return "Not important right now"
        }
    }
}
```

---

## Gesture Handling

### Swipe Actions

```swift
struct SwipeableCard<Content: View>: View {
    let content: Content
    let onSwipeRight: () async -> Void
    let onSwipeLeft: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isCompleting = false
    
    private let threshold: CGFloat = 100
    
    init(
        @ViewBuilder content: () -> Content,
        onSwipeRight: @escaping () async -> Void,
        onSwipeLeft: @escaping () -> Void
    ) {
        self.content = content()
        self.onSwipeRight = onSwipeRight
        self.onSwipeLeft = onSwipeLeft
    }
    
    var body: some View {
        ZStack {
            // Background actions
            HStack {
                // Complete action (right swipe)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .opacity(offset > 0 ? min(offset / threshold, 1) : 0)
                
                Spacer()
                
                // Defer action (left swipe)
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .opacity(offset < 0 ? min(-offset / threshold, 1) : 0)
            }
            .padding(.horizontal, 20)
            
            // Card content
            content
                .offset(x: offset)
                .gesture(dragGesture)
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                if value.translation.width > threshold {
                    // Complete with animation
                    withAnimation(.spring()) {
                        offset = UIScreen.main.bounds.width
                    }
                    Task {
                        await onSwipeRight()
                    }
                } else if value.translation.width < -threshold {
                    // Defer
                    onSwipeLeft()
                    withAnimation(.spring()) {
                        offset = 0
                    }
                } else {
                    // Snap back
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
            }
    }
}
```

---

## Testing Support

### Preview Helpers

```swift
extension Task {
    static var preview: Task {
        let task = Task(
            rawInput: "order contacts, need to take prescription renewal phone exam",
            title: "Order contacts from 1-800 Contacts",
            energyLevel: .low,
            estimatedMinutes: 10,
            status: .active,
            taskType: .obligation
        )
        task.subtasks = [
            Subtask(title: "Take vision exam on phone", order: 0),
            Subtask(title: "Submit prescription", order: 1),
            Subtask(title: "Place order", order: 2)
        ]
        return task
    }
    
    static var completed: Task {
        let task = Task.preview
        task.status = .completed
        task.completedAt = .now
        return task
    }
}
```

### View Model Mocking

```swift
// For previews and tests
@Observable
final class MockNowViewModel: NowViewModelProtocol {
    var tasks: [Task] = [.preview]
    var isLoading = false
    var error: Error?
    
    func loadTasks() async {
        // Simulate delay
        try? await Task.sleep(for: .seconds(1))
        tasks = [.preview, .preview, .preview]
    }
}
```

---

## Accessibility

```swift
struct TaskCard: View {
    let task: Task
    
    var body: some View {
        // ... card content ...
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityHint("Double tap to view details. Swipe right to complete. Swipe left to defer.")
    .accessibilityAddTraits(.isButton)
    
    private var accessibilityLabel: String {
        var label = task.title
        label += ". \(task.energyLevel.title)."
        label += " Estimated \(task.estimatedMinutes) minutes."
        if task.subtasks.count > 1 {
            let completed = task.subtasks.filter(\.isCompleted).count
            label += " \(completed) of \(task.subtasks.count) steps completed."
        }
        return label
    }
}
```

---

*This agent file should be consulted for all feature implementation and UI development work on Stride.*

