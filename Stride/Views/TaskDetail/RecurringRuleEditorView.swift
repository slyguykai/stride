import SwiftUI
import SwiftData

struct RecurringRuleEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: Task

    @State private var frequency: Int
    @State private var period: RecurringPeriod
    @State private var windowStart: Date
    @State private var windowEnd: Date
    @State private var preferredDays: Set<Int>

    init(task: Task) {
        self.task = task
        let rule = task.recurringRule
        _frequency = State(initialValue: rule?.frequency ?? 3)
        _period = State(initialValue: rule?.period ?? .week)
        _windowStart = State(initialValue: rule?.windowStart ?? Date())
        _windowEnd = State(initialValue: rule?.windowEnd ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        _preferredDays = State(initialValue: Set(rule?.preferredDays ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Frequency") {
                    Stepper(value: $frequency, in: 1...14) {
                        Text("\(frequency) times per \(period.title.lowercased())")
                    }
                    Picker("Period", selection: $period) {
                        ForEach(RecurringPeriod.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                }

                Section("Window") {
                    DatePicker("Start", selection: $windowStart, displayedComponents: [.date])
                    DatePicker("End", selection: $windowEnd, in: windowStart..., displayedComponents: [.date])
                }

                Section("Preferred days") {
                    DayPicker(selectedDays: $preferredDays)
                }

                if task.recurringRule != nil {
                    Section {
                        Button("Clear recurrence", role: .destructive) {
                            if let rule = task.recurringRule {
                                modelContext.delete(rule)
                            }
                            task.recurringRule = nil
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Recurring Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRule()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveRule() {
        let rule = task.recurringRule ?? RecurringRule(
            frequency: frequency,
            period: period,
            windowStart: windowStart,
            windowEnd: windowEnd,
            preferredDays: Array(preferredDays).sorted(),
            task: task
        )
        rule.frequency = frequency
        rule.period = period
        rule.windowStart = windowStart
        rule.windowEnd = windowEnd
        rule.preferredDays = Array(preferredDays).sorted()
        rule.task = task
        task.recurringRule = rule
        modelContext.insert(rule)
        try? modelContext.save()
    }
}

struct DayPicker: View {
    @Binding var selectedDays: Set<Int>

    private let days = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, label in
                Button {
                    toggleDay(index + 1)
                } label: {
                    HStack {
                        Text(label)
                        Spacer()
                        if selectedDays.contains(index + 1) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
