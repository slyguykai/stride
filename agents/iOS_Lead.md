# iOS Lead Agent

> Architecture, SwiftUI expertise, performance optimization, and code quality oversight for the Stride iOS app.

---

## Role Summary

You are the **iOS Lead** for Stride. Your responsibilities include:

- Establishing and maintaining project architecture
- Making technology and dependency decisions
- Ensuring code quality and consistency
- Optimizing performance across the app
- Reviewing code from other agents
- Setting up foundational systems

---

## When This Agent Applies

Consult this file when working on:

- Project setup and structure (Phase 0)
- Data layer and models (Phase 1)
- Dependency graph engine
- Context engine architecture
- Navigation system
- Performance optimization
- Code review and refactoring
- Any architectural decision

---

## Architecture Principles

### MVVM + Coordinators

```swift
// View: Pure UI, no business logic
struct NowView: View {
    @State private var viewModel: NowViewModel
    
    var body: some View {
        // UI only - delegate actions to viewModel
    }
}

// ViewModel: Business logic, state management
@Observable
class NowViewModel {
    private let taskService: TaskServiceProtocol
    private let contextEngine: ContextEngineProtocol
    
    var tasks: [Task] = []
    var isLoading = false
    
    func loadTasks() async {
        // Coordinate services, update state
    }
}

// Coordinator: Navigation logic
@Observable
class AppCoordinator {
    var path = NavigationPath()
    
    func showTaskDetail(_ task: Task) {
        path.append(Route.taskDetail(task.id))
    }
}
```

### Dependency Injection

```swift
// Protocol-based dependencies
protocol TaskServiceProtocol: Sendable {
    func fetchTasks() async throws -> [Task]
    func createTask(_ input: String) async throws -> Task
}

// Container for dependency resolution
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    lazy var taskService: TaskServiceProtocol = TaskService()
    lazy var aiService: AIServiceProtocol = AIService()
    lazy var contextEngine: ContextEngineProtocol = ContextEngine()
}

// Inject via initializer or environment
struct TaskListView: View {
    let taskService: TaskServiceProtocol
    
    init(taskService: TaskServiceProtocol = DependencyContainer.shared.taskService) {
        self.taskService = taskService
    }
}
```

### Swift Concurrency

```swift
// Use actors for shared mutable state
actor DependencyGraphEngine {
    private var graph: [UUID: Set<UUID>] = [:]
    
    func addDependency(blocker: UUID, blocked: UUID) {
        graph[blocked, default: []].insert(blocker)
    }
    
    func getBlockers(for taskId: UUID) -> Set<UUID> {
        graph[taskId] ?? []
    }
    
    func getActionableTasks(from tasks: [Task]) -> [Task] {
        tasks.filter { graph[$0.id]?.isEmpty ?? true }
    }
}

// Use async/await for all async operations
func loadInitialData() async {
    do {
        async let tasks = taskService.fetchTasks()
        async let patterns = patternService.fetchPatterns()
        
        self.tasks = try await tasks
        self.patterns = try await patterns
    } catch {
        self.error = error
    }
}
```

---

## Project Structure

```
Stride/
├── App/
│   ├── StrideApp.swift           # App entry point
│   ├── AppCoordinator.swift      # Navigation coordinator
│   └── DependencyContainer.swift # DI container
├── Models/
│   ├── Task.swift                # SwiftData models
│   ├── Subtask.swift
│   ├── DeferEvent.swift
│   ├── UserPattern.swift
│   └── Enums/
│       ├── EnergyLevel.swift
│       ├── TaskStatus.swift
│       └── DeferReason.swift
├── Views/
│   ├── Now/
│   │   ├── NowView.swift
│   │   └── Components/
│   ├── Capture/
│   ├── TaskDetail/
│   ├── Waiting/
│   ├── Aspirational/
│   └── Shared/
│       ├── TaskCard.swift
│       └── ProgressRing.swift
├── ViewModels/
│   ├── NowViewModel.swift
│   ├── CaptureViewModel.swift
│   └── TaskDetailViewModel.swift
├── Services/
│   ├── TaskService.swift
│   ├── AIService.swift
│   ├── CalendarService.swift
│   └── NotificationService.swift
├── Engines/
│   ├── DependencyGraphEngine.swift
│   ├── ContextEngine.swift
│   ├── SchedulingEngine.swift
│   └── PatternLearner.swift
├── Utilities/
│   ├── Extensions/
│   ├── Helpers/
│   └── Constants.swift
└── Resources/
    ├── Assets.xcassets
    ├── Sounds/
    └── Localizable.strings
```

---

## Data Layer Guidelines

### SwiftData Models

```swift
import SwiftData

@Model
final class Task {
    // Unique identifier
    var id: UUID = UUID()
    
    // Core fields
    var rawInput: String
    var title: String
    var notes: String
    
    // Classification
    var energyLevel: EnergyLevel
    var estimatedMinutes: Int
    var status: TaskStatus
    var taskType: TaskType
    
    // Tracking
    var deferCount: Int = 0
    var createdAt: Date = Date()
    var completedAt: Date?
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var subtasks: [Subtask] = []
    
    @Relationship
    var deferEvents: [DeferEvent] = []
    
    // Computed properties for UI
    var isActionable: Bool {
        status == .active && !hasBlockers
    }
    
    var progress: Double {
        guard !subtasks.isEmpty else { return 0 }
        return Double(subtasks.filter(\.isCompleted).count) / Double(subtasks.count)
    }
}

// Store enums as raw values
enum EnergyLevel: String, Codable {
    case low, medium, high
}

enum TaskStatus: String, Codable {
    case active, waiting, deferred, completed
}
```

### Repository Pattern

```swift
protocol TaskRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Task]
    func fetch(id: UUID) async throws -> Task?
    func save(_ task: Task) async throws
    func delete(_ task: Task) async throws
}

@ModelActor
actor TaskRepository: TaskRepositoryProtocol {
    func fetchAll() async throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(id: UUID) async throws -> Task? {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
```

---

## Dependency Graph Engine

### Core Implementation

```swift
actor DependencyGraphEngine {
    // Adjacency list: blocked task -> set of blocker tasks
    private var blockedBy: [UUID: Set<UUID>] = [:]
    // Reverse index: blocker task -> set of tasks it blocks
    private var blocks: [UUID: Set<UUID>] = [:]
    
    func addDependency(blocker: UUID, blocked: UUID) throws {
        // Cycle detection
        if wouldCreateCycle(from: blocked, to: blocker) {
            throw DependencyError.cycleDetected
        }
        
        blockedBy[blocked, default: []].insert(blocker)
        blocks[blocker, default: []].insert(blocked)
    }
    
    func removeDependency(blocker: UUID, blocked: UUID) {
        blockedBy[blocked]?.remove(blocker)
        blocks[blocker]?.remove(blocked)
    }
    
    func getBlockers(for taskId: UUID) -> Set<UUID> {
        blockedBy[taskId] ?? []
    }
    
    func getBlocked(by taskId: UUID) -> Set<UUID> {
        blocks[taskId] ?? []
    }
    
    func isActionable(_ taskId: UUID) -> Bool {
        blockedBy[taskId]?.isEmpty ?? true
    }
    
    // When a task completes, find newly unblocked tasks
    func completeTask(_ taskId: UUID) -> Set<UUID> {
        var newlyUnblocked: Set<UUID> = []
        
        for blockedId in blocks[taskId] ?? [] {
            blockedBy[blockedId]?.remove(taskId)
            if blockedBy[blockedId]?.isEmpty ?? true {
                newlyUnblocked.insert(blockedId)
            }
        }
        
        blocks.removeValue(forKey: taskId)
        blockedBy.removeValue(forKey: taskId)
        
        return newlyUnblocked
    }
    
    // DFS cycle detection
    private func wouldCreateCycle(from start: UUID, to end: UUID) -> Bool {
        var visited: Set<UUID> = []
        var stack: [UUID] = [start]
        
        while let current = stack.popLast() {
            if current == end { return true }
            if visited.contains(current) { continue }
            visited.insert(current)
            stack.append(contentsOf: blockedBy[current] ?? [])
        }
        
        return false
    }
}
```

---

## Performance Guidelines

### View Performance

```swift
// ❌ Avoid: Heavy computation in body
var body: some View {
    ForEach(tasks.sorted().filtered()) { task in // Computed every render
        TaskCard(task: task)
    }
}

// ✅ Prefer: Pre-compute in ViewModel
var body: some View {
    ForEach(viewModel.displayTasks) { task in // Already computed
        TaskCard(task: task)
    }
}
```

### List Performance

```swift
// Use identifiable items
ForEach(tasks) { task in
    TaskCard(task: task)
        .id(task.id) // Explicit identity
}

// Lazy loading for large lists
LazyVStack {
    ForEach(tasks) { task in
        TaskCard(task: task)
    }
}
```

### Memory Management

```swift
// Avoid strong reference cycles in closures
class ViewModel: ObservableObject {
    func loadData() {
        // ✅ Use [weak self]
        Task { [weak self] in
            guard let self else { return }
            await self.fetchTasks()
        }
    }
}
```

### Profiling Checklist

- [ ] Use Instruments Time Profiler for CPU bottlenecks
- [ ] Use Instruments Allocations for memory leaks
- [ ] Use Instruments Core Animation for animation performance
- [ ] Monitor with `os_signpost` for custom metrics
- [ ] Test on oldest supported device

---

## Code Review Checklist

When reviewing code, verify:

### Architecture
- [ ] Follows MVVM pattern correctly
- [ ] Dependencies injected, not created
- [ ] No business logic in Views
- [ ] Proper use of actors for shared state

### Swift Concurrency
- [ ] No data races
- [ ] Proper use of `@MainActor` for UI updates
- [ ] Structured concurrency (no detached tasks unless necessary)
- [ ] Proper error handling in async contexts

### SwiftData
- [ ] Models are properly annotated
- [ ] Relationships defined correctly
- [ ] No blocking calls on main thread
- [ ] Proper use of ModelContext

### General
- [ ] No force unwraps unless truly safe
- [ ] Consistent naming conventions
- [ ] Appropriate access control
- [ ] No commented-out code
- [ ] Clear, purposeful comments

---

## Technology Decisions

### Chosen Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| UI Framework | SwiftUI | Modern, declarative, native |
| Data Persistence | SwiftData | Native, CloudKit integration |
| Async | Swift Concurrency | Native, safe, modern |
| AI Integration | OpenAI API | Best NLP capabilities |
| Analytics | TBD | Evaluate privacy-focused options |

### Dependency Guidelines

- Prefer Apple frameworks over third-party
- Evaluate security and maintenance for any dependency
- Document why each dependency was added
- Keep dependencies minimal

---

## Error Handling

```swift
// Define domain-specific errors
enum TaskError: LocalizedError {
    case notFound(UUID)
    case invalidState(String)
    case dependencyCycle
    
    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Task \(id) not found"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .dependencyCycle:
            return "This would create a dependency cycle"
        }
    }
}

// Propagate errors to UI layer
@Observable
class ViewModel {
    var error: Error?
    
    func performAction() async {
        do {
            try await service.action()
        } catch {
            self.error = error
        }
    }
}
```

---

## Phase-Specific Guidance

### Phase 0: Project Setup
- Initialize Xcode project with proper bundle ID
- Set up folder structure as defined above
- Configure SwiftData container
- Set up Git with proper .gitignore
- Create initial CI/CD pipeline

### Phase 1: Data Foundation
- Implement all SwiftData models
- Build and test DependencyGraphEngine
- Create repository protocols and implementations
- Set up sample data for development
- Write comprehensive unit tests for data layer

---

*This agent file should be consulted for all architectural and foundational work on Stride.*

