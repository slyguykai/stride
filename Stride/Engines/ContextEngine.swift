import EventKit
import Foundation
import SwiftData

/// Current user context for task ranking and predictions
struct UserContext: Sendable {
    let timestamp: Date
    let hourOfDay: Int
    let dayOfWeek: Int
    let isWeekend: Bool
    
    // Activity metrics
    let recentCompletions: Int       // Last 2 hours
    let recentDefers: Int            // Last 2 hours
    let completionsToday: Int
    let defersToday: Int
    
    // Predicted state
    let estimatedEnergy: Float       // 0-100
    let productivityLevel: ProductivityLevel
    
    // Calendar context
    let isBusy: Bool
    let minutesUntilNextEvent: Int?
    let justFinishedMeeting: Bool
    
    enum ProductivityLevel: String, Sendable {
        case low, medium, high, peak
    }
}

/// Ranked task with prediction scores
struct RankedTask: Sendable {
    let taskID: UUID
    let completionProbability: Float  // 0-1
    let priorityScore: Float          // 0-100
    let reasons: [String]
}

/// Personal context learned from user behavior
struct PersonalContextEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let category: String              // "vendor", "timing", "preference"
    let key: String                   // e.g., "contacts_vendor"
    let value: String                 // e.g., "1-800 Contacts"
    let confidence: Float             // 0-1
    let occurrences: Int
    let lastSeen: Date
    let isUserEdited: Bool
    
    init(
        category: String,
        key: String,
        value: String,
        confidence: Float = 0.5,
        occurrences: Int = 1,
        isUserEdited: Bool = false
    ) {
        self.id = UUID()
        self.category = category
        self.key = key
        self.value = value
        self.confidence = confidence
        self.occurrences = occurrences
        self.lastSeen = Date()
        self.isUserEdited = isUserEdited
    }
}

/// Actor-based context engine for thread-safe predictions
actor ContextEngine {
    private var behaviorDataset: BehaviorDataset
    private var personalContext: [PersonalContextEntry]
    private let calendarService: CalendarServiceProtocol?
    
    private let datasetKey = "stride_behavior_dataset"
    private let contextKey = "stride_personal_context"
    
    init(calendarService: CalendarServiceProtocol? = nil) {
        self.calendarService = calendarService
        self.behaviorDataset = BehaviorDataset()
        self.personalContext = []
        
        // Load persisted data  
        _Concurrency.Task {
            await loadPersistedData()
        }
    }
    
    // MARK: - Context Retrieval
    
    func getCurrentContext() async -> UserContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let dayOfWeek = calendar.component(.weekday, from: now)
        
        // Get recent activity
        let twoHoursAgo = now.addingTimeInterval(-7200)
        let recentFeatures = behaviorDataset.features.filter { $0.timestamp >= twoHoursAgo }
        let recentCompletions = recentFeatures.filter { $0.wasCompleted }.count
        let recentDefers = recentFeatures.filter { $0.wasDeferred }.count
        
        let startOfDay = calendar.startOfDay(for: now)
        let todayFeatures = behaviorDataset.features.filter { $0.timestamp >= startOfDay }
        let completionsToday = todayFeatures.filter { $0.wasCompleted }.count
        let defersToday = todayFeatures.filter { $0.wasDeferred }.count
        
        // Predict energy
        let estimatedEnergy = await predictEnergy(at: now)
        
        // Determine productivity level
        let productivityLevel = determineProductivityLevel(
            energy: estimatedEnergy,
            recentCompletions: recentCompletions,
            recentDefers: recentDefers
        )
        
        // Calendar context (if available)
        var isBusy = false
        var minutesUntilNext: Int? = nil
        var justFinishedMeeting = false
        
        if let calendarService {
            do {
                let events = try await calendarService.fetchEvents(
                    from: now.addingTimeInterval(-1800),
                    to: now.addingTimeInterval(3600)
                )
                isBusy = events.contains { (event: EKEvent) in
                    event.startDate <= now && event.endDate > now
                }
                if let nextEvent = events.first(where: { (event: EKEvent) in event.startDate > now }) {
                    minutesUntilNext = Int(nextEvent.startDate.timeIntervalSince(now) / 60)
                }
                justFinishedMeeting = events.contains { (event: EKEvent) in
                    event.endDate <= now && event.endDate > now.addingTimeInterval(-900)
                }
            } catch {
                // Calendar access failed, use defaults
            }
        }
        
        return UserContext(
            timestamp: now,
            hourOfDay: hour,
            dayOfWeek: dayOfWeek,
            isWeekend: calendar.isDateInWeekend(now),
            recentCompletions: recentCompletions,
            recentDefers: recentDefers,
            completionsToday: completionsToday,
            defersToday: defersToday,
            estimatedEnergy: estimatedEnergy,
            productivityLevel: productivityLevel,
            isBusy: isBusy,
            minutesUntilNextEvent: minutesUntilNext,
            justFinishedMeeting: justFinishedMeeting
        )
    }
    
    // MARK: - Predictions
    
    func predictEnergy(at time: Date) async -> Float {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        
        // Get historical completion rate for this hour
        let hourCompletionRate = behaviorDataset.completionRate(for: hour)
        
        // Base energy from time of day patterns
        let baseEnergy = baseEnergyForHour(hour)
        
        // Blend historical data with base assumptions
        let historicalWeight = min(Float(behaviorDataset.features.count) / 100.0, 0.7)
        let blendedEnergy = (Float(hourCompletionRate) * historicalWeight * 100) +
                            (baseEnergy * (1 - historicalWeight))
        
        return max(0, min(100, blendedEnergy))
    }
    
    func rankTasks(_ tasks: [Task]) async -> [RankedTask] {
        let context = await getCurrentContext()
        
        return tasks.map { task in
            let probability = predictCompletionProbability(for: task, context: context)
            let priority = calculatePriorityScore(for: task, context: context, probability: probability)
            let reasons = generateReasons(for: task, context: context, probability: probability)
            
            return RankedTask(
                taskID: task.id,
                completionProbability: probability,
                priorityScore: priority,
                reasons: reasons
            )
        }
        .sorted { $0.priorityScore > $1.priorityScore }
    }
    
    func shouldNotify(for task: Task) async -> Bool {
        let context = await getCurrentContext()
        
        // Don't notify if busy
        if context.isBusy { return false }
        
        // Don't notify in low productivity periods
        if context.productivityLevel == .low { return false }
        
        // Don't notify if too many recent notifications
        if context.completionsToday + context.defersToday > 8 { return false }
        
        // Check if this is a good time for this task
        let probability = predictCompletionProbability(for: task, context: context)
        return probability > 0.5
    }
    
    // MARK: - Behavior Recording
    
    func recordCompletion(for task: Task, timeToComplete: TimeInterval?) async {
        let context = await getCurrentContext()
        let feature = UserBehaviorFeatures(
            task: task,
            wasCompleted: true,
            timeToComplete: timeToComplete,
            completionsToday: context.completionsToday,
            defersToday: context.defersToday
        )
        behaviorDataset.add(feature)
        await persistData()
        
        // Extract personal context from completed task
        await extractPersonalContext(from: task)
    }
    
    func recordDefer(for task: Task, reason: DeferReason) async {
        let context = await getCurrentContext()
        let feature = UserBehaviorFeatures(
            task: task,
            wasCompleted: false,
            deferReason: reason,
            completionsToday: context.completionsToday,
            defersToday: context.defersToday
        )
        behaviorDataset.add(feature)
        await persistData()
    }
    
    // MARK: - Personal Context
    
    func getPersonalContext() -> [PersonalContextEntry] {
        personalContext.sorted { $0.confidence > $1.confidence }
    }
    
    func updatePersonalContext(_ entry: PersonalContextEntry) async {
        if let index = personalContext.firstIndex(where: { $0.id == entry.id }) {
            personalContext[index] = entry
        } else {
            personalContext.append(entry)
        }
        await persistData()
    }
    
    func deletePersonalContext(_ entry: PersonalContextEntry) async {
        personalContext.removeAll { $0.id == entry.id }
        await persistData()
    }
    
    func getContextSuggestions(for taskTitle: String) -> [String] {
        // Find relevant personal context for this task
        let lowercased = taskTitle.lowercased()
        return personalContext
            .filter { lowercased.contains($0.key.lowercased()) || 
                      lowercased.contains($0.value.lowercased()) }
            .map { "\($0.key): \($0.value)" }
    }
    
    // MARK: - Statistics
    
    func getStatistics() -> ContextStatistics {
        let dataset = behaviorDataset
        return ContextStatistics(
            totalRecordings: dataset.features.count,
            overallCompletionRate: dataset.completionRate,
            bestHours: dataset.bestHoursForCompletion(),
            personalContextCount: personalContext.count
        )
    }
    
    // MARK: - Private Helpers
    
    private func baseEnergyForHour(_ hour: Int) -> Float {
        // Default energy curve based on typical circadian patterns
        switch hour {
        case 6...8: return 60   // Morning ramp-up
        case 9...11: return 85  // Peak morning
        case 12...13: return 55 // Post-lunch dip
        case 14...16: return 75 // Afternoon recovery
        case 17...19: return 65 // Evening decline
        case 20...22: return 45 // Night wind-down
        default: return 30      // Late night / early morning
        }
    }
    
    private func determineProductivityLevel(
        energy: Float,
        recentCompletions: Int,
        recentDefers: Int
    ) -> UserContext.ProductivityLevel {
        let completionRatio = recentCompletions + recentDefers == 0 
            ? 0.5 
            : Double(recentCompletions) / Double(recentCompletions + recentDefers)
        
        let combinedScore = (Double(energy) / 100.0 * 0.6) + (completionRatio * 0.4)
        
        switch combinedScore {
        case 0.8...: return .peak
        case 0.6..<0.8: return .high
        case 0.4..<0.6: return .medium
        default: return .low
        }
    }
    
    private func predictCompletionProbability(for task: Task, context: UserContext) -> Float {
        var probability: Float = 0.5
        
        // Energy matching boost
        let taskEnergy = energyLevelToFloat(task.energyLevel)
        let energyMatch = 1.0 - abs(taskEnergy - context.estimatedEnergy / 100.0)
        probability += energyMatch * 0.2
        
        // Historical completion rate for this task type
        let typeRate = behaviorDataset.completionRate(for: task.taskType.rawValue)
        probability += Float(typeRate - 0.5) * 0.2
        
        // Hour-based completion rate
        let hourRate = behaviorDataset.completionRate(for: context.hourOfDay)
        probability += Float(hourRate - 0.5) * 0.15
        
        // Defer streak penalty
        let deferPenalty = Float(task.deferCount) * 0.03
        probability -= min(deferPenalty, 0.2)
        
        // Quick task bonus
        if task.estimatedMinutes <= 5 {
            probability += 0.1
        }
        
        // Deadline urgency
        if let deadline = task.deadline {
            let hoursToDeadline = deadline.timeIntervalSinceNow / 3600
            if hoursToDeadline <= 4 {
                probability += 0.15
            } else if hoursToDeadline <= 24 {
                probability += 0.08
            }
        }
        
        return max(0.1, min(0.95, probability))
    }
    
    private func calculatePriorityScore(for task: Task, context: UserContext, probability: Float) -> Float {
        var score = probability * 50 // Base from probability
        
        // Deadline urgency
        if let deadline = task.deadline {
            let hoursToDeadline = Float(deadline.timeIntervalSinceNow / 3600)
            if hoursToDeadline <= 0 {
                score += 30 // Overdue
            } else if hoursToDeadline <= 4 {
                score += 25
            } else if hoursToDeadline <= 24 {
                score += 15
            }
        }
        
        // Energy matching
        let energyMatch = matchEnergyLevel(task.energyLevel, context: context)
        score += energyMatch * 10
        
        // Quick win bonus when energy is medium/low
        if task.estimatedMinutes <= 5 && context.estimatedEnergy < 60 {
            score += 10
        }
        
        // Productivity momentum
        if context.productivityLevel == .peak || context.productivityLevel == .high {
            score += 5
        }
        
        return max(0, min(100, score))
    }
    
    private func generateReasons(for task: Task, context: UserContext, probability: Float) -> [String] {
        var reasons: [String] = []
        
        if probability > 0.7 {
            reasons.append("High completion likelihood now")
        }
        
        if matchEnergyLevel(task.energyLevel, context: context) > 0.7 {
            reasons.append("Matches current energy")
        }
        
        if task.estimatedMinutes <= 5 {
            reasons.append("Quick win")
        }
        
        if let deadline = task.deadline, deadline.timeIntervalSinceNow < 86400 {
            reasons.append("Due soon")
        }
        
        if task.deferCount >= 3 {
            reasons.append("Been deferred multiple times")
        }
        
        return reasons
    }
    
    private func matchEnergyLevel(_ level: EnergyLevel, context: UserContext) -> Float {
        let taskEnergy = energyLevelToFloat(level)
        let currentEnergy = context.estimatedEnergy / 100.0
        return 1.0 - abs(taskEnergy - currentEnergy)
    }
    
    private func energyLevelToFloat(_ level: EnergyLevel) -> Float {
        switch level {
        case .low: return 0.3
        case .medium: return 0.6
        case .high: return 0.9
        }
    }
    
    private func extractPersonalContext(from task: Task) async {
        // Simple entity extraction from completed tasks
        let title = task.title.lowercased()
        let rawInput = task.rawInput.lowercased()
        
        // Extract vendor/service mentions
        let vendorPatterns = [
            ("1-800", "contacts_vendor", "1-800 Contacts"),
            ("amazon", "shopping_vendor", "Amazon"),
            ("costco", "shopping_vendor", "Costco"),
            ("pharmacy", "rx_vendor", "Pharmacy")
        ]
        
        for (pattern, key, value) in vendorPatterns {
            if title.contains(pattern) || rawInput.contains(pattern) {
                await addOrUpdateContext(category: "vendor", key: key, value: value)
            }
        }
        
        // Extract timing preferences
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        let dayOfWeek = calendar.component(.weekday, from: Date())
        
        // Track when this task type is typically completed
        let timeKey = "preferred_\(task.taskType.rawValue)_hour"
        await addOrUpdateContext(
            category: "timing",
            key: timeKey,
            value: "\(hour)"
        )
        
        // Track day preferences
        let dayKey = "preferred_\(task.taskType.rawValue)_day"
        await addOrUpdateContext(
            category: "timing",
            key: dayKey,
            value: "\(dayOfWeek)"
        )
    }
    
    private func addOrUpdateContext(category: String, key: String, value: String) async {
        if let index = personalContext.firstIndex(where: { $0.key == key }) {
            var existing = personalContext[index]
            // Increase confidence and occurrences
            let newConfidence = min(1.0, existing.confidence + 0.1)
            let newEntry = PersonalContextEntry(
                category: category,
                key: key,
                value: value,
                confidence: newConfidence,
                occurrences: existing.occurrences + 1,
                isUserEdited: existing.isUserEdited
            )
            personalContext[index] = newEntry
        } else {
            let entry = PersonalContextEntry(
                category: category,
                key: key,
                value: value
            )
            personalContext.append(entry)
        }
    }
    
    // MARK: - Persistence
    
    private func loadPersistedData() async {
        // Load behavior dataset
        if let data = UserDefaults.standard.data(forKey: datasetKey),
           let dataset = try? JSONDecoder().decode(BehaviorDataset.self, from: data) {
            self.behaviorDataset = dataset
        }
        
        // Load personal context
        if let data = UserDefaults.standard.data(forKey: contextKey),
           let context = try? JSONDecoder().decode([PersonalContextEntry].self, from: data) {
            self.personalContext = context
        }
    }
    
    private func persistData() async {
        // Save behavior dataset
        if let data = try? JSONEncoder().encode(behaviorDataset) {
            UserDefaults.standard.set(data, forKey: datasetKey)
        }
        
        // Save personal context
        if let data = try? JSONEncoder().encode(personalContext) {
            UserDefaults.standard.set(data, forKey: contextKey)
        }
    }
}

// MARK: - Statistics

struct ContextStatistics: Sendable {
    let totalRecordings: Int
    let overallCompletionRate: Double
    let bestHours: [Int]
    let personalContextCount: Int
}

