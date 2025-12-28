import SwiftUI
import SwiftData

/// Sheet for splitting an expanded task into two separate tasks
struct SplitTaskSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let task: Task
    let snapshot: TaskSnapshot
    let scopeCreepResult: ScopeCreepResult
    
    @State private var newTaskTitle: String = ""
    @State private var keepOriginalSubtasks: Bool = true
    @State private var moveAddedSubtasks: Bool = true
    
    private let detector = ScopeCreepDetector()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summarySection
                    newTaskSection
                    subtaskDistributionSection
                    previewSection
                }
                .padding()
            }
            .navigationTitle("Split Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Split") {
                        performSplit()
                        dismiss()
                    }
                    .disabled(newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What happened", systemImage: "arrow.up.left.and.arrow.down.right")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Original estimate")
                    Spacer()
                    Text("\(snapshot.estimatedMinutes) min")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Current estimate")
                    Spacer()
                    Text("\(task.estimatedMinutes) min")
                        .foregroundStyle(.orange)
                }
                
                if scopeCreepResult.addedSubtasks > 0 {
                    HStack {
                        Text("Subtasks added")
                        Spacer()
                        Text("+\(scopeCreepResult.addedSubtasks)")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var newTaskSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("New task", systemImage: "plus.circle")
                .font(.headline)
            
            TextField("Title for the split-off task", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
            
            Text("The new steps will be moved to this task")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var subtaskDistributionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What to move", systemImage: "arrow.triangle.branch")
                .font(.headline)
            
            VStack(spacing: 0) {
                Toggle("Keep original \(snapshot.subtaskCount) steps in main task", isOn: $keepOriginalSubtasks)
                    .disabled(true) // Always keep original
                    .padding()
                
                Divider()
                
                Toggle("Move \(scopeCreepResult.addedSubtasks) new steps to split task", isOn: $moveAddedSubtasks)
                    .padding()
            }
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("After split", systemImage: "eye")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Original task preview
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("\(snapshot.estimatedMinutes) min")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "checklist")
                        Text("\(snapshot.subtaskCount) steps")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                // New task preview
                VStack(alignment: .leading, spacing: 6) {
                    Text(newTaskTitle.isEmpty ? "New task" : newTaskTitle)
                        .font(.subheadline.bold())
                        .lineLimit(2)
                        .foregroundStyle(newTaskTitle.isEmpty ? .secondary : .primary)
                    
                    HStack {
                        Image(systemName: "clock")
                        Text("\(scopeCreepResult.addedMinutes) min")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "checklist")
                        Text("\(scopeCreepResult.addedSubtasks) steps")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func performSplit() {
        let splitResult = detector.splitTask(
            original: snapshot,
            edited: task,
            newTaskTitle: newTaskTitle
        )
        
        // Insert the new task
        modelContext.insert(splitResult.newTask)
        
        // Move the added subtasks to the new task
        if moveAddedSubtasks {
            for subtask in splitResult.movedSubtasks {
                // Remove from original task
                task.subtasks.removeAll { $0.id == subtask.id }
                
                // Create new subtask for the new task
                let newSubtask = Subtask(
                    title: subtask.title,
                    isCompleted: subtask.isCompleted,
                    order: subtask.order,
                    parentTask: splitResult.newTask
                )
                modelContext.insert(newSubtask)
                splitResult.newTask.subtasks.append(newSubtask)
            }
        }
        
        // Revert original task's estimated time
        task.estimatedMinutes = snapshot.estimatedMinutes
        
        // Haptic feedback
        HapticEngine.shared.success()
        
        try? modelContext.save()
    }
}

