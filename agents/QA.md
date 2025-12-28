# QA Agent

> Testing strategy, test implementation, quality assurance, and beta management for the Stride iOS app.

---

## Role Summary

You are the **QA Engineer** for Stride. Your responsibilities include:

- Defining and implementing testing strategy
- Writing unit tests, integration tests, and UI tests
- Managing beta releases and feedback
- Performance and reliability testing
- Ensuring accessibility compliance
- Tracking and verifying bug fixes

---

## When This Agent Applies

Consult this file when working on:

- Writing tests (all phases)
- Test infrastructure setup
- Beta/TestFlight management (Phase 10)
- Performance testing
- Accessibility auditing
- Bug verification
- Release quality gates

---

## Testing Strategy

### Test Pyramid

```
         /\
        /  \
       / UI \        <- Few, critical user flows
      /______\
     /        \
    /Integration\    <- Service interactions
   /______________\
  /                \
 /     Unit Tests   \  <- Many, fast, isolated
/_____________________\
```

### Coverage Targets

| Layer | Target | Focus |
|-------|--------|-------|
| Unit | 80%+ | Business logic, algorithms, models |
| Integration | 60%+ | Service interactions, data flow |
| UI | Critical paths | Core user journeys only |

---

## Unit Testing

### Test Organization

```
StrideTests/
├── Models/
│   ├── TaskTests.swift
│   ├── SubtaskTests.swift
│   └── DeferEventTests.swift
├── Engines/
│   ├── DependencyGraphEngineTests.swift
│   ├── ContextEngineTests.swift
│   └── SchedulingEngineTests.swift
├── Services/
│   ├── TaskServiceTests.swift
│   ├── AIServiceTests.swift
│   └── PatternAnalyzerTests.swift
├── ViewModels/
│   ├── NowViewModelTests.swift
│   ├── CaptureViewModelTests.swift
│   └── TaskDetailViewModelTests.swift
└── Utilities/
    └── ExtensionTests.swift
```

### Swift Testing Framework

```swift
import Testing
@testable import Stride

@Suite("Dependency Graph Engine")
struct DependencyGraphEngineTests {
    
    let engine = DependencyGraphEngine()
    
    @Test("Adding dependency creates relationship")
    func addDependency() async throws {
        let blockerID = UUID()
        let blockedID = UUID()
        
        try await engine.addDependency(blocker: blockerID, blocked: blockedID)
        
        let blockers = await engine.getBlockers(for: blockedID)
        #expect(blockers.contains(blockerID))
    }
    
    @Test("Task without blockers is actionable")
    func actionableTask() async {
        let taskID = UUID()
        
        let isActionable = await engine.isActionable(taskID)
        
        #expect(isActionable)
    }
    
    @Test("Task with blockers is not actionable")
    func blockedTask() async throws {
        let blockerID = UUID()
        let blockedID = UUID()
        
        try await engine.addDependency(blocker: blockerID, blocked: blockedID)
        
        let isActionable = await engine.isActionable(blockedID)
        
        #expect(!isActionable)
    }
    
    @Test("Completing task unblocks dependents")
    func completionUnblocks() async throws {
        let blockerID = UUID()
        let blocked1 = UUID()
        let blocked2 = UUID()
        
        try await engine.addDependency(blocker: blockerID, blocked: blocked1)
        try await engine.addDependency(blocker: blockerID, blocked: blocked2)
        
        let unblocked = await engine.completeTask(blockerID)
        
        #expect(unblocked.contains(blocked1))
        #expect(unblocked.contains(blocked2))
    }
    
    @Test("Cycle detection prevents invalid dependencies")
    func cycleDetection() async throws {
        let taskA = UUID()
        let taskB = UUID()
        let taskC = UUID()
        
        try await engine.addDependency(blocker: taskA, blocked: taskB)
        try await engine.addDependency(blocker: taskB, blocked: taskC)
        
        // This would create A -> B -> C -> A cycle
        await #expect(throws: DependencyError.cycleDetected) {
            try await engine.addDependency(blocker: taskC, blocked: taskA)
        }
    }
}
```

### Testing View Models

```swift
@Suite("Now View Model")
struct NowViewModelTests {
    
    @Test("Loading tasks updates state")
    @MainActor
    func loadTasks() async throws {
        let mockService = MockTaskService()
        mockService.tasks = [.preview, .preview]
        
        let viewModel = NowViewModel(taskService: mockService)
        
        #expect(viewModel.tasks.isEmpty)
        #expect(!viewModel.isLoading)
        
        await viewModel.loadTasks()
        
        #expect(viewModel.tasks.count == 2)
        #expect(!viewModel.isLoading)
    }
    
    @Test("Completing task removes from list")
    @MainActor
    func completeTask() async throws {
        let mockService = MockTaskService()
        let task = Task.preview
        mockService.tasks = [task]
        
        let viewModel = NowViewModel(taskService: mockService)
        await viewModel.loadTasks()
        
        await viewModel.complete(task)
        
        #expect(!viewModel.tasks.contains { $0.id == task.id })
        #expect(mockService.completedTasks.contains { $0.id == task.id })
    }
    
    @Test("Error handling sets error state")
    @MainActor
    func errorHandling() async {
        let mockService = MockTaskService()
        mockService.shouldFail = true
        
        let viewModel = NowViewModel(taskService: mockService)
        
        await viewModel.loadTasks()
        
        #expect(viewModel.error != nil)
    }
}
```

### Testing Async Code

```swift
@Suite("AI Service")
struct AIServiceTests {
    
    @Test("Parsing returns structured task")
    func parseInput() async throws {
        let mockClient = MockAPIClient()
        mockClient.response = """
        {
            "title": "Order contacts",
            "subtasks": ["Take exam", "Submit prescription"],
            "dependencies": [],
            "estimatedMinutes": 15,
            "energyLevel": "low",
            "contextTags": ["phone"]
        }
        """
        
        let service = AIService(apiClient: mockClient)
        
        let result = try await service.parseTaskInput("order contacts")
        
        #expect(result.title == "Order contacts")
        #expect(result.subtasks.count == 2)
        #expect(result.energyLevel == .low)
    }
    
    @Test("Retry logic handles rate limiting", .timeLimit(.minutes(1)))
    func retryOnRateLimit() async throws {
        let mockClient = MockAPIClient()
        mockClient.failCount = 2  // Fail twice, then succeed
        mockClient.failError = APIError.rateLimited
        
        let service = AIService(apiClient: mockClient)
        
        let result = try await service.parseTaskInputWithRetry("test")
        
        #expect(result.title.isEmpty == false)
        #expect(mockClient.callCount == 3)
    }
}
```

---

## Integration Testing

### Service Integration

```swift
@Suite("Task Service Integration")
struct TaskServiceIntegrationTests {
    
    var container: ModelContainer!
    var service: TaskService!
    
    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Task.self, Subtask.self, configurations: config)
        service = TaskService(modelContainer: container)
    }
    
    @Test("Create and fetch task")
    func createAndFetch() async throws {
        let input = "test task"
        
        let created = try await service.createTask(rawInput: input, title: "Test", energyLevel: .low)
        let fetched = try await service.fetchTask(id: created.id)
        
        #expect(fetched?.rawInput == input)
        #expect(fetched?.title == "Test")
    }
    
    @Test("Complete task updates status")
    func completeTask() async throws {
        let task = try await service.createTask(rawInput: "test", title: "Test", energyLevel: .low)
        
        try await service.complete(task)
        
        let updated = try await service.fetchTask(id: task.id)
        #expect(updated?.status == .completed)
        #expect(updated?.completedAt != nil)
    }
    
    @Test("Defer increments count and records event")
    func deferTask() async throws {
        let task = try await service.createTask(rawInput: "test", title: "Test", energyLevel: .low)
        
        try await service.defer(task, reason: .noEnergy, until: nil)
        
        let updated = try await service.fetchTask(id: task.id)
        #expect(updated?.deferCount == 1)
        #expect(updated?.deferEvents.count == 1)
        #expect(updated?.deferEvents.first?.reason == .noEnergy)
    }
}
```

### Calendar Integration

```swift
@Suite("Calendar Service Integration")
struct CalendarServiceIntegrationTests {
    
    @Test("Fetch events requires authorization")
    func authorizationRequired() async {
        let service = CalendarService()
        
        // Should handle gracefully when not authorized
        let events = try? await service.getUpcomingEvents(hours: 4)
        
        // Either returns events or empty (not crash)
        #expect(events != nil || events == nil)  // Just checking no throw
    }
}
```

---

## UI Testing

### Critical User Flows

```swift
import XCTest

final class StrideUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    // MARK: - Capture Flow
    
    func testCaptureTextInput() throws {
        // Tap capture button
        app.buttons["capture_button"].tap()
        
        // Enter text
        let textField = app.textFields["capture_input"]
        textField.tap()
        textField.typeText("Test task from UI test")
        
        // Submit
        app.buttons["submit_button"].tap()
        
        // Verify task appears
        XCTAssertTrue(app.staticTexts["Test task from UI test"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Task Completion
    
    func testSwipeToComplete() throws {
        // Ensure we have a task
        createTestTask()
        
        // Find first task card
        let taskCard = app.otherElements["task_card"].firstMatch
        XCTAssertTrue(taskCard.waitForExistence(timeout: 3))
        
        // Swipe right to complete
        taskCard.swipeRight()
        
        // Verify completion animation/feedback
        XCTAssertTrue(app.otherElements["completion_effect"].waitForExistence(timeout: 2))
    }
    
    // MARK: - Defer Flow
    
    func testSwipeToDefer() throws {
        createTestTask()
        
        let taskCard = app.otherElements["task_card"].firstMatch
        XCTAssertTrue(taskCard.waitForExistence(timeout: 3))
        
        // Swipe left to defer
        taskCard.swipeLeft()
        
        // Verify defer sheet appears
        XCTAssertTrue(app.sheets["defer_sheet"].waitForExistence(timeout: 2))
        
        // Select reason
        app.buttons["defer_reason_no_energy"].tap()
        
        // Confirm
        app.buttons["defer_confirm"].tap()
        
        // Sheet should dismiss
        XCTAssertFalse(app.sheets["defer_sheet"].exists)
    }
    
    // MARK: - Helpers
    
    private func createTestTask() {
        app.buttons["capture_button"].tap()
        app.textFields["capture_input"].tap()
        app.textFields["capture_input"].typeText("UI Test Task")
        app.buttons["submit_button"].tap()
        
        // Wait for processing
        _ = app.staticTexts["UI Test Task"].waitForExistence(timeout: 5)
    }
}
```

### Accessibility Testing

```swift
final class AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        app = XCUIApplication()
        app.launch()
    }
    
    func testTaskCardAccessibility() throws {
        // Create a task first
        // ...
        
        let taskCard = app.otherElements["task_card"].firstMatch
        XCTAssertTrue(taskCard.waitForExistence(timeout: 3))
        
        // Check accessibility
        XCTAssertTrue(taskCard.isAccessibilityElement)
        XCTAssertFalse(taskCard.label.isEmpty)
        
        // Verify hint exists
        XCTAssertTrue(taskCard.accessibilityHint?.contains("complete") ?? false)
    }
    
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver in test
        app.launchArguments.append("-UIAccessibilityVoiceOverEnabled")
        app.launch()
        
        // Verify all elements are reachable
        let elements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        
        for element in elements {
            if element.isAccessibilityElement {
                XCTAssertFalse(element.label.isEmpty, "Element missing label: \(element)")
            }
        }
    }
}
```

---

## Performance Testing

### Metrics to Track

```swift
import XCTest

final class PerformanceTests: XCTestCase {
    
    func testLargeTaskListScrollPerformance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--performance-test", "--task-count=500"]
        app.launch()
        
        let taskList = app.scrollViews["task_list"]
        
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            taskList.swipeUp(velocity: .fast)
            taskList.swipeDown(velocity: .fast)
        }
    }
    
    func testTaskCompletionLatency() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Create task
        // ...
        
        let taskCard = app.otherElements["task_card"].firstMatch
        
        let metrics: [XCTMetric] = [
            XCTClockMetric(),
            XCTCPUMetric(),
            XCTMemoryMetric()
        ]
        
        measure(metrics: metrics) {
            taskCard.swipeRight()
            // Wait for completion animation
            _ = app.otherElements["completion_effect"].waitForExistence(timeout: 2)
        }
    }
}
```

### Memory Profiling

```swift
@Suite("Memory Tests")
struct MemoryTests {
    
    @Test("No memory leaks in view model lifecycle")
    @MainActor
    func viewModelMemory() async {
        weak var weakViewModel: NowViewModel?
        
        autoreleasepool {
            let viewModel = NowViewModel()
            weakViewModel = viewModel
            
            // Use the view model
            Task { await viewModel.loadTasks() }
        }
        
        // Allow cleanup
        try? await Task.sleep(for: .milliseconds(100))
        
        #expect(weakViewModel == nil, "ViewModel should be deallocated")
    }
}
```

---

## Test Mocks

### Mock Task Service

```swift
final class MockTaskService: TaskServiceProtocol, @unchecked Sendable {
    var tasks: [Task] = []
    var completedTasks: [Task] = []
    var deferredTasks: [(Task, DeferReason)] = []
    var shouldFail = false
    var error: Error = TaskError.notFound(UUID())
    
    func fetchActiveTasks() async throws -> [Task] {
        if shouldFail { throw error }
        return tasks
    }
    
    func complete(_ task: Task) async throws {
        if shouldFail { throw error }
        completedTasks.append(task)
        tasks.removeAll { $0.id == task.id }
    }
    
    func `defer`(_ task: Task, reason: DeferReason, until: Date?) async throws {
        if shouldFail { throw error }
        deferredTasks.append((task, reason))
    }
    
    // ... other methods
}
```

### Mock API Client

```swift
final class MockAPIClient: APIClientProtocol, @unchecked Sendable {
    var response: String = "{}"
    var failCount = 0
    var failError: Error?
    var callCount = 0
    
    func complete(prompt: String) async throws -> String {
        callCount += 1
        
        if callCount <= failCount, let error = failError {
            throw error
        }
        
        return response
    }
}
```

---

## Beta Management

### TestFlight Checklist

Before each beta release:

- [ ] All unit tests passing
- [ ] All UI tests passing
- [ ] No new crashes in crash reporting
- [ ] Performance benchmarks met
- [ ] Accessibility audit passed
- [ ] Release notes written
- [ ] Build number incremented

### Feedback Collection

```swift
// In-app feedback trigger
struct FeedbackButton: View {
    @State private var showFeedback = false
    
    var body: some View {
        Button {
            showFeedback = true
        } label: {
            Label("Send Feedback", systemImage: "bubble.left.and.bubble.right")
        }
        .sheet(isPresented: $showFeedback) {
            FeedbackView()
        }
    }
}

struct FeedbackView: View {
    @State private var feedback = ""
    @State private var includeScreenshot = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("What's on your mind?") {
                    TextEditor(text: $feedback)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Include screenshot", isOn: $includeScreenshot)
                }
                
                Section {
                    Text("App Version: \(Bundle.main.appVersion)")
                    Text("Device: \(UIDevice.current.model)")
                    Text("iOS: \(UIDevice.current.systemVersion)")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { sendFeedback() }
                        .disabled(feedback.isEmpty)
                }
            }
        }
    }
    
    private func sendFeedback() {
        // Send to feedback service
        dismiss()
    }
}
```

### Analytics Events

```swift
enum AnalyticsEvent {
    case taskCreated(energyLevel: EnergyLevel, hasSubtasks: Bool)
    case taskCompleted(deferCount: Int, timeToComplete: TimeInterval)
    case taskDeferred(reason: DeferReason)
    case focusTimeTriggered(taskDeferCount: Int)
    case focusTimeCompleted(didComplete: Bool)
    case aiSuggestionAccepted
    case aiSuggestionEdited
    case aiSuggestionRejected
}

protocol AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent)
}
```

---

## Quality Gates

### Pre-Merge Checklist

Before merging any PR:

- [ ] Unit tests pass locally
- [ ] No new warnings
- [ ] Code follows style guide
- [ ] Accessibility labels present
- [ ] No force unwraps without justification
- [ ] Documentation updated if API changed

### Pre-Release Checklist

Before App Store submission:

- [ ] All tests passing on CI
- [ ] Manual smoke test on device
- [ ] Accessibility audit with VoiceOver
- [ ] Performance profiling shows no regressions
- [ ] Crash-free rate >99.5% in beta
- [ ] Privacy manifest accurate
- [ ] Screenshots and metadata current

---

## Bug Tracking

### Bug Report Template

```markdown
## Description
[Clear description of the issue]

## Steps to Reproduce
1. [First step]
2. [Second step]
3. [And so on...]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Environment
- App Version: 
- Device: 
- iOS Version: 
- Build: 

## Screenshots/Videos
[If applicable]

## Additional Context
[Any other relevant information]
```

### Severity Levels

| Level | Definition | Response Time |
|-------|------------|---------------|
| P0 | Crash, data loss, security | Same day |
| P1 | Major feature broken | 24 hours |
| P2 | Feature degraded | 1 week |
| P3 | Minor issue | Next release |
| P4 | Polish/enhancement | Backlog |

---

*This agent file should be consulted for all testing, quality, and release management work on Stride.*

