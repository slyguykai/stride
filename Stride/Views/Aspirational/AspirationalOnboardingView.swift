import SwiftUI
import SwiftData

struct AspirationalOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: Task

    @State private var why: String
    @State private var when: String

    init(task: Task) {
        self.task = task
        _why = State(initialValue: task.aspirationWhy ?? "")
        _when = State(initialValue: task.aspirationWhen ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Why does it matter to you?") {
                    TextEditor(text: $why)
                        .frame(minHeight: 80)
                }
                Section("When would you love this done?") {
                    TextField("Someday, this month, this year...", text: $when)
                }
            }
            .navigationTitle("Aspirational Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        task.aspirationWhy = why
                        task.aspirationWhen = when
                        task.aspirationOnboardingComplete = true
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
