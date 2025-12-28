# Backend & AI Agent

> Prompt engineering, API integration, machine learning, and data processing for the Stride iOS app.

---

## Role Summary

You are the **Backend & AI Engineer** for Stride. Your responsibilities include:

- Designing and refining AI prompts for task parsing
- Integrating with OpenAI/Claude APIs
- Building the pattern learning system
- Implementing Core ML models
- Creating the context engine
- Processing natural language input

---

## When This Agent Applies

Consult this file when working on:

- AI task parsing (Phase 2)
- Prompt engineering and refinement
- API client implementation
- Pattern detection and learning (Phase 9)
- Context engine development
- Core ML model training
- Voice transcription processing
- Personal context learning

---

## AI Service Architecture

### Service Protocol

```swift
protocol AIServiceProtocol: Sendable {
    func parseTaskInput(_ input: String) async throws -> ParsedTask
    func generateSubtasks(for task: String, context: TaskContext?) async throws -> [String]
    func estimateEnergy(for task: String) async throws -> EnergyLevel
    func generateFollowUpMessage(for waitingTask: Task) async throws -> String
    func microBreakdown(task: Task, blockReason: String) async throws -> [String]
}

struct ParsedTask: Codable, Sendable {
    let title: String
    let subtasks: [String]
    let dependencies: [String]
    let estimatedMinutes: Int
    let energyLevel: EnergyLevel
    let contextTags: [String]
}

struct TaskContext: Sendable {
    let recentTasks: [String]
    let userPatterns: [String]
    let personalContext: [String: String]
}
```

### Implementation

```swift
actor AIService: AIServiceProtocol {
    private let apiClient: APIClientProtocol
    private let cache: NSCache<NSString, CacheEntry>
    
    init(apiClient: APIClientProtocol = OpenAIClient()) {
        self.apiClient = apiClient
        self.cache = NSCache()
        self.cache.countLimit = 100
    }
    
    func parseTaskInput(_ input: String) async throws -> ParsedTask {
        // Check cache first
        let cacheKey = input.hashValue.description as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached.parsedTask
        }
        
        let prompt = buildParsingPrompt(input: input)
        let response = try await apiClient.complete(prompt: prompt)
        let parsed = try JSONDecoder().decode(ParsedTask.self, from: response.data(using: .utf8)!)
        
        // Cache result
        cache.setObject(CacheEntry(parsedTask: parsed), forKey: cacheKey)
        
        return parsed
    }
    
    private func buildParsingPrompt(input: String) -> String {
        """
        You are a task parsing assistant for a personal productivity app. 
        Parse the user's brain dump into structured task data.
        
        User input: "\(input)"
        
        Extract and return JSON with:
        {
            "title": "Clear, actionable task title (one sentence)",
            "subtasks": ["Ordered list of atomic steps to complete the task"],
            "dependencies": ["Things that must happen before this task can start"],
            "estimatedMinutes": <integer estimate>,
            "energyLevel": "low" | "medium" | "high",
            "contextTags": ["relevant context like 'phone', 'computer', 'errand', 'home', 'work'"]
        }
        
        Guidelines:
        - Title should be actionable: "Order contacts" not "Contacts"
        - Subtasks should be atomic: single clear actions
        - Dependencies are blockers mentioned in the input
        - Energy: low = quick/easy, medium = moderate focus, high = significant effort
        - Be concise but complete
        
        Return only valid JSON, no explanation.
        """
    }
}
```

---

## Prompt Engineering Guidelines

### Principles

1. **Be specific**: Vague prompts produce vague results
2. **Provide examples**: Show the format you want
3. **Set constraints**: Define what NOT to do
4. **Request structure**: Ask for JSON or specific formats
5. **Include context**: User patterns improve accuracy

### Task Parsing Prompt (Production)

```swift
func buildParsingPrompt(input: String, context: TaskContext?) -> String {
    var prompt = """
    You are a task parsing assistant for Stride, a personal productivity app.
    Your job is to understand messy human thoughts and structure them into actionable tasks.
    
    ## User's Input
    "\(input)"
    
    """
    
    // Add personal context if available
    if let context = context, !context.personalContext.isEmpty {
        prompt += """
        
        ## Known Personal Context
        \(context.personalContext.map { "- \($0.key): \($0.value)" }.joined(separator: "\n"))
        
        """
    }
    
    prompt += """
    
    ## Instructions
    Parse this into a structured task. Return valid JSON only.
    
    {
        "title": "Single clear action statement",
        "subtasks": [
            "First atomic step",
            "Second atomic step"
        ],
        "dependencies": [
            "Blockers or prerequisites mentioned"
        ],
        "estimatedMinutes": 15,
        "energyLevel": "low|medium|high",
        "contextTags": ["phone", "computer", "errand", "home", "work", "waiting"]
    }
    
    ## Rules
    - Title: Use imperative mood ("Order contacts" not "Ordering contacts")
    - Subtasks: Each should take <5 minutes. If longer, break down further.
    - Dependencies: Only include if explicitly mentioned or strongly implied
    - Time: Be realistic. Include buffer for context switching.
    - Energy: 
      - low: Quick, minimal decisions, <10 min
      - medium: Some focus needed, 10-30 min
      - high: Deep work, decisions, emotional labor, >30 min
    - Tags: Include all that apply
    
    Return ONLY the JSON object. No markdown, no explanation.
    """
    
    return prompt
}
```

### Micro-Breakdown Prompt (Focus Time)

```swift
func buildMicroBreakdownPrompt(task: Task, blockReason: String) -> String {
    """
    A user has deferred this task \(task.deferCount) times.
    
    Task: "\(task.title)"
    Original thought: "\(task.rawInput)"
    They said they're blocked because: "\(blockReason)"
    
    Help them get unstuck by finding the absolute smallest first step.
    
    Think about:
    - What's the very first physical action? (Open app, pick up phone, etc.)
    - Is there a smaller version of this task?
    - What information do they need to start?
    - Is there a way to make this take 2 minutes?
    
    Return JSON:
    {
        "microSteps": [
            "Tiny first action (should take <2 min)",
            "Next tiny action",
            "..."
        ],
        "simplifiedVersion": "If the full task is too much, here's a simpler version that still provides value",
        "missingInfo": "What they might need to gather first, if anything"
    }
    
    Be encouraging but practical. The goal is momentum, not perfection.
    """
}
```

### Follow-Up Message Generation

```swift
func buildFollowUpPrompt(task: Task, daysSinceRequest: Int) -> String {
    """
    Generate a polite follow-up message for this waiting task.
    
    Task: "\(task.title)"
    Original request context: "\(task.rawInput)"
    Days waiting: \(daysSinceRequest)
    
    Generate a brief, friendly follow-up message. The tone should be:
    - Professional but warm
    - Not passive-aggressive
    - Direct about the ask
    - Appropriate for the wait time
    
    Return JSON:
    {
        "subject": "Email subject if applicable",
        "message": "The follow-up message body",
        "tone": "friendly|professional|urgent"
    }
    
    Keep it under 50 words. Be human.
    """
}
```

---

## API Client Implementation

### OpenAI Client

```swift
actor OpenAIClient: APIClientProtocol {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.openai.com/v1")!
    private let session: URLSession
    private let model = "gpt-4o-mini" // Fast and cost-effective
    
    init(apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "") {
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }
    
    func complete(prompt: String) async throws -> String {
        let request = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: "You are a helpful task parsing assistant. Always respond with valid JSON only."),
                .init(role: "user", content: prompt)
            ],
            temperature: 0.3, // Low temperature for consistent parsing
            maxTokens: 500
        )
        
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("chat/completions"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        
        guard let content = completion.choices.first?.message.content else {
            throw APIError.noContent
        }
        
        return content
    }
}

// MARK: - Request/Response Types

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
    
    struct Message: Encodable {
        let role: String
        let content: String
    }
}

struct ChatCompletionResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)
    case noContent
    case rateLimited
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP error: \(code)"
        case .noContent: return "No content in response"
        case .rateLimited: return "Rate limited. Please try again."
        case .invalidJSON: return "Could not parse AI response"
        }
    }
}
```

### Error Handling & Retry Logic

```swift
extension AIService {
    func parseTaskInputWithRetry(_ input: String, maxRetries: Int = 3) async throws -> ParsedTask {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await parseTaskInput(input)
            } catch let error as APIError {
                lastError = error
                
                switch error {
                case .rateLimited:
                    // Exponential backoff
                    let delay = Double(attempt * attempt)
                    try await Task.sleep(for: .seconds(delay))
                case .invalidJSON:
                    // Try with more explicit prompt
                    // Could modify prompt here
                    continue
                default:
                    throw error
                }
            }
        }
        
        throw lastError ?? APIError.invalidResponse
    }
}
```

---

## Pattern Learning System

### Pattern Data Model

```swift
@Model
final class UserBehaviorEvent {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var eventType: BehaviorEventType
    
    // Task context
    var taskEnergyLevel: String
    var taskType: String
    var estimatedMinutes: Int
    var actualMinutes: Int?
    
    // Time context
    var hourOfDay: Int
    var dayOfWeek: Int
    var isWeekend: Bool
    
    // Outcome
    var wasCompleted: Bool
    var deferCount: Int
    var deferReasons: [String]
}

enum BehaviorEventType: String, Codable {
    case taskCreated
    case taskCompleted
    case taskDeferred
    case subtaskCompleted
    case focusTimeTriggered
    case focusTimeCompleted
}
```

### Pattern Analyzer

```swift
actor PatternAnalyzer {
    private let modelContext: ModelContext
    
    struct TimePattern: Sendable {
        let hour: Int
        let completionRate: Double
        let preferredEnergyLevel: EnergyLevel
        let avgTasksCompleted: Double
    }
    
    struct TaskTypePattern: Sendable {
        let taskType: String
        let avgCompletionTime: TimeInterval
        let deferRate: Double
        let bestTimeOfDay: Int
        let worstTimeOfDay: Int
    }
    
    func analyzeTimePatterns() async throws -> [TimePattern] {
        let events = try await fetchRecentEvents(days: 30)
        
        var hourlyStats: [Int: (completed: Int, total: Int, energyLevels: [EnergyLevel])] = [:]
        
        for event in events {
            let hour = event.hourOfDay
            var stats = hourlyStats[hour] ?? (0, 0, [])
            stats.total += 1
            if event.wasCompleted {
                stats.completed += 1
            }
            if let energy = EnergyLevel(rawValue: event.taskEnergyLevel) {
                stats.energyLevels.append(energy)
            }
            hourlyStats[hour] = stats
        }
        
        return hourlyStats.map { hour, stats in
            TimePattern(
                hour: hour,
                completionRate: stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0,
                preferredEnergyLevel: mostCommon(stats.energyLevels) ?? .medium,
                avgTasksCompleted: Double(stats.completed)
            )
        }.sorted { $0.hour < $1.hour }
    }
    
    func predictBestTime(for task: Task) async throws -> [Date] {
        let patterns = try await analyzeTimePatterns()
        
        // Find hours with high completion rate for this energy level
        let goodHours = patterns
            .filter { $0.preferredEnergyLevel == task.energyLevel }
            .filter { $0.completionRate > 0.6 }
            .sorted { $0.completionRate > $1.completionRate }
            .prefix(3)
            .map { $0.hour }
        
        // Convert to actual dates in the next 7 days
        let calendar = Calendar.current
        var suggestions: [Date] = []
        
        for day in 0..<7 {
            guard let baseDate = calendar.date(byAdding: .day, value: day, to: .now) else { continue }
            
            for hour in goodHours {
                if let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: baseDate),
                   date > .now {
                    suggestions.append(date)
                }
            }
        }
        
        return Array(suggestions.prefix(5))
    }
    
    private func mostCommon<T: Hashable>(_ array: [T]) -> T? {
        var counts: [T: Int] = [:]
        array.forEach { counts[$0, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
```

---

## Context Engine

### Implementation

```swift
actor ContextEngine: ContextEngineProtocol {
    private let patternAnalyzer: PatternAnalyzer
    private let calendarService: CalendarServiceProtocol
    
    struct UserContext: Sendable {
        let currentHour: Int
        let dayOfWeek: Int
        let isWeekend: Bool
        let estimatedEnergy: Float // 0-1
        let recentCompletions: Int
        let upcomingCalendarEvents: Int
        let minutesFreeBeforeNextEvent: Int?
    }
    
    func getCurrentContext() async throws -> UserContext {
        let now = Date()
        let calendar = Calendar.current
        
        let hour = calendar.component(.hour, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        let isWeekend = dayOfWeek == 1 || dayOfWeek == 7
        
        // Get calendar info
        let events = try await calendarService.getUpcomingEvents(hours: 4)
        let nextEvent = events.first
        let minutesFree = nextEvent.map { 
            calendar.dateComponents([.minute], from: now, to: $0.startDate).minute 
        } ?? nil
        
        // Estimate energy based on patterns and time
        let energy = await estimateCurrentEnergy(hour: hour, dayOfWeek: dayOfWeek)
        
        // Get recent completion count
        let recentCompletions = try await getCompletionCount(lastHours: 2)
        
        return UserContext(
            currentHour: hour,
            dayOfWeek: dayOfWeek,
            isWeekend: isWeekend,
            estimatedEnergy: energy,
            recentCompletions: recentCompletions,
            upcomingCalendarEvents: events.count,
            minutesFreeBeforeNextEvent: minutesFree ?? nil
        )
    }
    
    func rankTasks(_ tasks: [Task]) async throws -> [Task] {
        let context = try await getCurrentContext()
        
        let scored = tasks.map { task -> (Task, Float) in
            var score: Float = 0
            
            // Energy match bonus
            let energyMatch = matchesEnergy(task.energyLevel, context.estimatedEnergy)
            score += energyMatch * 20
            
            // Time available bonus
            if let freeMinutes = context.minutesFreeBeforeNextEvent {
                if task.estimatedMinutes <= freeMinutes {
                    score += 15 // Fits in available time
                }
                if task.estimatedMinutes <= 5 {
                    score += 10 // Quick win bonus
                }
            }
            
            // Dependency-free bonus
            if task.status == .active { // Not blocked
                score += 25
            }
            
            // Defer penalty
            score -= Float(task.deferCount) * 5
            
            // Waiting tasks excluded
            if task.status == .waiting {
                score = -1000
            }
            
            return (task, score)
        }
        
        return scored
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }
    
    private func matchesEnergy(_ taskEnergy: EnergyLevel, _ currentEnergy: Float) -> Float {
        let taskEnergyValue: Float = switch taskEnergy {
        case .low: 0.3
        case .medium: 0.6
        case .high: 0.9
        }
        
        // Higher score when task energy matches or is below current energy
        if taskEnergyValue <= currentEnergy {
            return 1.0
        } else {
            return max(0, 1.0 - (taskEnergyValue - currentEnergy))
        }
    }
    
    private func estimateCurrentEnergy(hour: Int, dayOfWeek: Int) async -> Float {
        // Base energy curve (typical human pattern)
        let baseEnergy: Float = switch hour {
        case 6...9: 0.7   // Morning ramp-up
        case 10...12: 0.9 // Peak morning
        case 13...14: 0.5 // Post-lunch dip
        case 15...17: 0.7 // Afternoon recovery
        case 18...20: 0.6 // Evening
        case 21...23: 0.3 // Night wind-down
        default: 0.2      // Late night/early morning
        }
        
        // Weekend adjustment (slightly lower urgency)
        let isWeekend = dayOfWeek == 1 || dayOfWeek == 7
        let weekendModifier: Float = isWeekend ? 0.9 : 1.0
        
        // TODO: Incorporate learned patterns
        // let learnedPattern = await patternAnalyzer.getEnergyPattern(hour: hour, dayOfWeek: dayOfWeek)
        
        return baseEnergy * weekendModifier
    }
}
```

---

## Personal Context Learning

### Entity Extraction

```swift
actor PersonalContextLearner {
    private var knownEntities: [String: String] = [:]
    
    // Learn from completed tasks
    func learnFromCompletion(_ task: Task) async {
        let input = task.rawInput.lowercased()
        
        // Extract vendor/service names
        if let vendor = extractVendor(from: input) {
            let category = categorize(task)
            knownEntities[category] = vendor
        }
        
        // Extract timing patterns
        if let duration = task.completedAt?.timeIntervalSince(task.createdAt) {
            await updateDurationEstimate(for: categorize(task), duration: duration)
        }
    }
    
    // Apply learned context to new tasks
    func enrichParsedTask(_ parsed: ParsedTask, originalInput: String) -> ParsedTask {
        var enriched = parsed
        
        // Add known vendor context
        for (category, vendor) in knownEntities {
            if originalInput.lowercased().contains(category) {
                enriched = ParsedTask(
                    title: parsed.title,
                    subtasks: parsed.subtasks,
                    dependencies: parsed.dependencies,
                    estimatedMinutes: parsed.estimatedMinutes,
                    energyLevel: parsed.energyLevel,
                    contextTags: parsed.contextTags + [vendor]
                )
            }
        }
        
        return enriched
    }
    
    private func extractVendor(from text: String) -> String? {
        // Known vendor patterns
        let vendorPatterns = [
            "1-800 contacts": "1-800 Contacts",
            "1800contacts": "1-800 Contacts",
            "amazon": "Amazon",
            "costco": "Costco",
            // Add more as learned
        ]
        
        for (pattern, vendor) in vendorPatterns {
            if text.contains(pattern) {
                return vendor
            }
        }
        
        return nil
    }
    
    private func categorize(_ task: Task) -> String {
        // Simple categorization based on content
        let content = (task.title + " " + task.rawInput).lowercased()
        
        if content.contains("contact") || content.contains("vision") {
            return "contacts"
        }
        if content.contains("prescription") || content.contains("medication") {
            return "prescriptions"
        }
        if content.contains("grocery") || content.contains("food") {
            return "groceries"
        }
        
        return "general"
    }
}
```

---

## Core ML Integration (Future)

### On-Device Model Training

```swift
import CreateML
import CoreML

actor OnDeviceModelTrainer {
    func trainCompletionPredictor() async throws -> MLModel {
        // Prepare training data from UserBehaviorEvents
        let trainingData = try await prepareTrainingData()
        
        // Create classifier
        let classifier = try MLBoostedTreeClassifier(
            trainingData: trainingData,
            targetColumn: "wasCompleted",
            featureColumns: [
                "hourOfDay",
                "dayOfWeek",
                "taskEnergyLevel",
                "estimatedMinutes",
                "deferCount"
            ]
        )
        
        // Export model
        let modelURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CompletionPredictor.mlmodel")
        
        try classifier.write(to: modelURL)
        
        return try MLModel(contentsOf: modelURL)
    }
    
    private func prepareTrainingData() async throws -> MLDataTable {
        // Fetch events and convert to MLDataTable
        // ...
    }
}
```

---

## Testing AI Components

### Mock AI Service

```swift
final class MockAIService: AIServiceProtocol, @unchecked Sendable {
    var parseResult: ParsedTask = ParsedTask(
        title: "Test task",
        subtasks: ["Step 1", "Step 2"],
        dependencies: [],
        estimatedMinutes: 10,
        energyLevel: .low,
        contextTags: ["test"]
    )
    
    var parseCallCount = 0
    
    func parseTaskInput(_ input: String) async throws -> ParsedTask {
        parseCallCount += 1
        return parseResult
    }
    
    // ... other mock implementations
}
```

### Prompt Testing

```swift
@Test
func testParsingPromptProducesValidJSON() async throws {
    let service = AIService(apiClient: realClient)
    
    let testInputs = [
        "order contacts, need to take prescription renewal phone exam",
        "call mom about thanksgiving plans",
        "finish quarterly report by friday"
    ]
    
    for input in testInputs {
        let result = try await service.parseTaskInput(input)
        
        #expect(!result.title.isEmpty)
        #expect(!result.subtasks.isEmpty)
        #expect(result.estimatedMinutes > 0)
    }
}
```

---

## Performance Considerations

### API Latency Mitigation

1. **Optimistic UI**: Show input immediately, parse in background
2. **Caching**: Cache parsed results for similar inputs
3. **Streaming**: Use streaming API for long responses
4. **Fallback**: Allow manual entry if API fails

### Cost Management

1. **Model Selection**: Use `gpt-4o-mini` for routine parsing
2. **Prompt Efficiency**: Keep prompts concise
3. **Batching**: Batch multiple requests when possible
4. **On-Device**: Move to Core ML for frequent operations

---

*This agent file should be consulted for all AI, ML, and backend integration work on Stride.*

