import SwiftUI
import SwiftData

struct WaitingConfigView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let task: Task

    @State private var contactName: String
    @State private var followUpIntervalDays: Int
    @State private var message: String

    init(task: Task) {
        self.task = task
        _contactName = State(initialValue: task.waitingContactName ?? "")
        _followUpIntervalDays = State(initialValue: task.waitingFollowUpIntervalDays ?? 3)
        _message = State(initialValue: task.waitingFollowUpMessage ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Contact") {
                    TextField("Who are you waiting on?", text: $contactName)
                }

                Section("Follow-up timing") {
                    Picker("Interval", selection: $followUpIntervalDays) {
                        Text("1 day").tag(1)
                        Text("2-3 days").tag(3)
                        Text("5-7 days").tag(6)
                        Text("Next week").tag(7)
                    }
                }

                Section("Message template") {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Waiting Details")
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
                }
            }
        }
    }

    private func save() {
        let viewModel = WaitingViewModel(modelContext: modelContext)
        viewModel.configureWaiting(
            task: task,
            contactName: contactName,
            followUpIntervalDays: followUpIntervalDays,
            customMessage: message
        )
    }
}
