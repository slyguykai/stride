import SwiftUI
import SwiftData

struct NotificationPreferencesView: View {
    @Environment(\.modelContext) private var modelContext

    @AppStorage(NotificationPreferencesStore.Keys.allowTimeBased)
    private var allowTimeBased = true
    @AppStorage(NotificationPreferencesStore.Keys.allowEnergyBased)
    private var allowEnergyBased = true
    @AppStorage(NotificationPreferencesStore.Keys.allowDeferReminders)
    private var allowDeferReminders = true
    @AppStorage(NotificationPreferencesStore.Keys.allowWaitingReminders)
    private var allowWaitingReminders = true
    @AppStorage(NotificationPreferencesStore.Keys.dailyLimit)
    private var dailyLimit = 3

    @State private var permissionStatus: String = "Not requested"
    @State private var isScheduling = false

    private let scheduler = NotificationScheduler()
    private let calendarService = CalendarService()

    var body: some View {
        Form {
            Section("Context-aware notifications") {
                Toggle("Time-based suggestions", isOn: $allowTimeBased)
                Toggle("Energy-based suggestions", isOn: $allowEnergyBased)
                Stepper(value: $dailyLimit, in: 1...5) {
                    Text("Daily limit: \(dailyLimit)")
                }
            }

            Section("Reminders") {
                Toggle("Defer reminders", isOn: $allowDeferReminders)
                Toggle("Waiting follow-ups", isOn: $allowWaitingReminders)
            }

            Section("Permissions") {
                Text("Status: \(permissionStatus)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("Request notification access") {
                    _Concurrency.Task {
                        let granted = await scheduler.requestAuthorization()
                        permissionStatus = granted ? "Granted" : "Denied"
                    }
                }
            }

            Section("Schedule") {
                Button(isScheduling ? "Scheduling..." : "Schedule suggestions now") {
                    _Concurrency.Task {
                        await scheduleNow()
                    }
                }
                .disabled(isScheduling)
            }
        }
        .navigationTitle("Notifications")
    }

    private func scheduleNow() async {
        isScheduling = true
        defer { isScheduling = false }
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
        )
        let tasks = (try? modelContext.fetch(descriptor)) ?? []
        let preferences = NotificationPreferencesStore.load()
        await scheduler.scheduleContextSuggestions(
            tasks: tasks,
            calendarService: calendarService,
            preferences: preferences
        )
    }
}
