import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class TaskDetailViewModel {
    let task: Task
    private let modelContext: ModelContext
    private let scopeCreepDetector = ScopeCreepDetector()

    var blockers: [Task] = []
    
    // Scope creep detection
    private(set) var snapshot: TaskSnapshot?
    private(set) var scopeCreepResult: ScopeCreepResult?
    var showSplitSheet = false

    init(task: Task, modelContext: ModelContext) {
        self.task = task
        self.modelContext = modelContext
        // Capture initial snapshot for scope creep detection
        self.snapshot = TaskSnapshot(task: task)
    }

    func toggleSubtask(_ subtask: Subtask) async {
        subtask.isCompleted.toggle()
        HapticEngine.shared.lightTap()
        AudioManager.shared.play(.completeSoft)
        try? modelContext.save()
        checkForScopeCreep()
    }

    func markWaiting() {
        task.status = .waiting
        try? modelContext.save()
    }

    func delete() {
        modelContext.delete(task)
        try? modelContext.save()
    }
    
    // MARK: - Scope Creep Detection
    
    /// Check if the task has expanded beyond thresholds
    func checkForScopeCreep() {
        guard let snapshot else { return }
        scopeCreepResult = scopeCreepDetector.detectScopeCreep(original: snapshot, edited: task)
    }
    
    /// Update task estimate and recheck scope creep
    func updateEstimate(_ minutes: Int) {
        task.estimatedMinutes = minutes
        try? modelContext.save()
        checkForScopeCreep()
    }
    
    /// Add a subtask and recheck scope creep
    func addSubtask(title: String) {
        let subtask = Subtask(
            title: title,
            isCompleted: false,
            order: task.subtasks.count,
            parentTask: task
        )
        modelContext.insert(subtask)
        task.subtasks.append(subtask)
        try? modelContext.save()
        checkForScopeCreep()
    }
    
    /// Accept the expanded scope - dismiss the warning
    func acceptScopeCreep() {
        // Create a new snapshot reflecting current state
        snapshot = TaskSnapshot(task: task)
        scopeCreepResult = nil
        HapticEngine.shared.lightTap()
    }
    
    /// Revert to original scope
    func revertScopeCreep() {
        guard let snapshot else { return }
        
        // Revert estimated time
        task.estimatedMinutes = snapshot.estimatedMinutes
        
        // Remove added subtasks (keep only original count)
        let sortedSubtasks = task.subtasks.sorted { $0.order < $1.order }
        let subtasksToRemove = Array(sortedSubtasks.suffix(from: min(snapshot.subtaskCount, sortedSubtasks.count)))
        
        for subtask in subtasksToRemove {
            task.subtasks.removeAll { $0.id == subtask.id }
            modelContext.delete(subtask)
        }
        
        try? modelContext.save()
        scopeCreepResult = nil
        HapticEngine.shared.mediumTap()
    }
    
    /// Initiate split task flow
    func initiateSplit() {
        showSplitSheet = true
    }
}
