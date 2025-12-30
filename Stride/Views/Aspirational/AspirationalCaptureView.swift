import SwiftUI
import SwiftData

struct AspirationalCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var why = ""
    @State private var when = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("What would you love to do?") {
                    TextField("Aspirational task", text: $title)
                }

                Section("Why does it matter to you?") {
                    TextEditor(text: $why)
                        .frame(minHeight: 80)
                }

                Section("When would you love this done?") {
                    TextField("Someday, this month, this year...", text: $when)
                }
            }
            .navigationTitle("New Aspirational")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let task = Task(
            rawInput: title,
            title: title,
            energyLevel: .medium,
            estimatedMinutes: 30,
            status: .active,
            taskType: .aspirational,
            aspirationWhy: why,
            aspirationWhen: when,
            aspirationOnboardingComplete: true
        )
        modelContext.insert(task)
        try? modelContext.save()
    }
}
