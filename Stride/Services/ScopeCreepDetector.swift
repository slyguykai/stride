import Foundation

/// Result of scope creep detection analysis
struct ScopeCreepResult: Sendable {
    enum Suggestion: String, Sendable {
        case split = "split"
        case keep = "keep"
        case revert = "revert"
    }
    
    let addedMinutes: Int
    let addedSubtasks: Int
    let addedDependencies: Int
    let descriptionExpansion: Int // character count increase
    let suggestion: Suggestion
    let severity: Severity
    
    enum Severity: Sendable {
        case mild     // Minor expansion, just a warning
        case moderate // Significant expansion, suggest split
        case severe   // Major expansion, strongly recommend split
    }
    
    var isSignificant: Bool {
        severity != .mild
    }
    
    var message: String {
        var parts: [String] = []
        
        if addedMinutes > 0 {
            parts.append("+\(addedMinutes) min")
        }
        if addedSubtasks > 0 {
            parts.append("+\(addedSubtasks) steps")
        }
        if addedDependencies > 0 {
            parts.append("+\(addedDependencies) blockers")
        }
        
        return parts.isEmpty ? "Task expanded" : parts.joined(separator: ", ")
    }
}

/// Snapshot of a task's state before editing
struct TaskSnapshot: Sendable {
    let id: UUID
    let title: String
    let notes: String
    let estimatedMinutes: Int
    let subtaskCount: Int
    let dependencyCount: Int
    let capturedAt: Date
    
    init(task: Task) {
        self.id = task.id
        self.title = task.title
        self.notes = task.notes
        self.estimatedMinutes = task.estimatedMinutes
        self.subtaskCount = task.subtasks.count
        self.dependencyCount = task.dependencies.count
        self.capturedAt = Date()
    }
}

/// Detects when a task's scope expands during editing
struct ScopeCreepDetector {
    
    // MARK: - Thresholds
    
    /// Minimum added minutes to trigger detection
    static let minTimeDelta = 15
    
    /// Minimum added subtasks to trigger detection
    static let minSubtaskDelta = 2
    
    /// Minimum added dependencies to trigger detection
    static let minDependencyDelta = 1
    
    /// Character increase threshold for notes expansion
    static let notesExpansionThreshold = 200
    
    // MARK: - Detection
    
    /// Analyze changes between original snapshot and current task state
    func detectScopeCreep(original: TaskSnapshot, edited: Task) -> ScopeCreepResult? {
        let subtaskDelta = edited.subtasks.count - original.subtaskCount
        let timeDelta = edited.estimatedMinutes - original.estimatedMinutes
        let dependencyDelta = edited.dependencies.count - original.dependencyCount
        let descriptionDelta = edited.notes.count - original.notes.count
        
        // No significant changes
        if subtaskDelta < Self.minSubtaskDelta &&
           timeDelta < Self.minTimeDelta &&
           dependencyDelta < Self.minDependencyDelta &&
           descriptionDelta < Self.notesExpansionThreshold {
            return nil
        }
        
        let severity = calculateSeverity(
            subtaskDelta: subtaskDelta,
            timeDelta: timeDelta,
            dependencyDelta: dependencyDelta,
            descriptionDelta: descriptionDelta
        )
        
        let suggestion: ScopeCreepResult.Suggestion = severity == .severe ? .split : .keep
        
        return ScopeCreepResult(
            addedMinutes: max(0, timeDelta),
            addedSubtasks: max(0, subtaskDelta),
            addedDependencies: max(0, dependencyDelta),
            descriptionExpansion: max(0, descriptionDelta),
            suggestion: suggestion,
            severity: severity
        )
    }
    
    /// Quick check without full analysis
    func hasSignificantChanges(original: TaskSnapshot, edited: Task) -> Bool {
        let subtaskDelta = edited.subtasks.count - original.subtaskCount
        let timeDelta = edited.estimatedMinutes - original.estimatedMinutes
        
        return subtaskDelta >= Self.minSubtaskDelta || timeDelta >= Self.minTimeDelta
    }
    
    // MARK: - Private
    
    private func calculateSeverity(
        subtaskDelta: Int,
        timeDelta: Int,
        dependencyDelta: Int,
        descriptionDelta: Int
    ) -> ScopeCreepResult.Severity {
        var score = 0
        
        // Score based on time increase
        if timeDelta >= 30 {
            score += 3
        } else if timeDelta >= 15 {
            score += 2
        } else if timeDelta >= 5 {
            score += 1
        }
        
        // Score based on subtask increase
        if subtaskDelta >= 4 {
            score += 3
        } else if subtaskDelta >= 2 {
            score += 2
        } else if subtaskDelta >= 1 {
            score += 1
        }
        
        // Score based on dependency increase
        if dependencyDelta >= 2 {
            score += 2
        } else if dependencyDelta >= 1 {
            score += 1
        }
        
        // Score based on description expansion
        if descriptionDelta >= 500 {
            score += 2
        } else if descriptionDelta >= 200 {
            score += 1
        }
        
        // Map score to severity
        switch score {
        case 0...2:
            return .mild
        case 3...5:
            return .moderate
        default:
            return .severe
        }
    }
}

// MARK: - Split Task Helper

extension ScopeCreepDetector {
    
    /// Create a new task from the expanded portion of an edited task
    struct SplitResult {
        let originalTask: Task
        let newTask: Task
        let movedSubtasks: [Subtask]
    }
    
    /// Split the expanded content into a new task
    func splitTask(
        original: TaskSnapshot,
        edited: Task,
        newTaskTitle: String
    ) -> SplitResult {
        // Identify which subtasks were added (beyond original count)
        let sortedSubtasks = edited.subtasks.sorted { $0.order < $1.order }
        let originalSubtasks = Array(sortedSubtasks.prefix(original.subtaskCount))
        let addedSubtasks = Array(sortedSubtasks.suffix(from: min(original.subtaskCount, sortedSubtasks.count)))
        
        // Calculate time for new task (proportional to moved subtasks)
        let addedTime = edited.estimatedMinutes - original.estimatedMinutes
        
        // Create the new task
        let newTask = Task(
            rawInput: "Split from: \(edited.title)",
            title: newTaskTitle.isEmpty ? "Continued: \(edited.title)" : newTaskTitle,
            notes: "",
            energyLevel: edited.energyLevel,
            estimatedMinutes: max(5, addedTime),
            status: .active,
            taskType: edited.taskType
        )
        
        // Revert original task
        edited.estimatedMinutes = original.estimatedMinutes
        
        // Move added subtasks to new task (conceptually - actual move handled by caller)
        for subtask in addedSubtasks {
            subtask.order = subtask.order - original.subtaskCount
        }
        
        return SplitResult(
            originalTask: edited,
            newTask: newTask,
            movedSubtasks: addedSubtasks
        )
    }
}

