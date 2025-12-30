import SwiftUI

struct DeferSheet: View {
    let task: Task
    let onDefer: (DeferReason, Date?) async -> Void

    @State private var selectedReason: DeferReason?
    @State private var selectedTime: Date?
    @State private var showTimePicker = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TaskCard(task: task, size: .small)
                    .allowsHitTesting(false)

                reasonButtons

                if selectedReason != nil {
                    timeOptions
                }

                Spacer()

                if selectedReason != nil {
                    confirmButton
                }
            }
            .padding()
            .navigationTitle("Defer Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var reasonButtons: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why are you deferring?")
                .font(.headline)

            ForEach(DeferReason.allCases, id: \.self) { reason in
                Button {
                    HapticEngine.shared.selectionChanged()
                    withAnimation(.strideQuick) { selectedReason = reason }
                } label: {
                    HStack {
                        Text(reason.emoji)
                        Text(reason.title)
                        Spacer()
                        if selectedReason == reason {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var timeOptions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remind me")
                .font(.headline)

            HStack(spacing: 12) {
                TimeOptionButton(title: "1 hour", time: .now.addingTimeInterval(3600)) {
                    selectedTime = $0
                }
                TimeOptionButton(title: "Tonight", time: todayAt(hour: 19)) {
                    selectedTime = $0
                }
                TimeOptionButton(title: "Tomorrow", time: tomorrowAt(hour: 9)) {
                    selectedTime = $0
                }
                TimeOptionButton(title: "Pick...", time: nil) { _ in
                    showTimePicker = true
                }
            }
        }
        .sheet(isPresented: $showTimePicker) {
            DatePicker("Select time", selection: Binding(
                get: { selectedTime ?? .now },
                set: { selectedTime = $0 }
            ), in: Date.now...)
                .datePickerStyle(.graphical)
                .presentationDetents([.medium])
                .padding()
        }
    }

    private var confirmButton: some View {
        Button {
            HapticEngine.shared.mediumTap()
            _Concurrency.Task {
                await onDefer(selectedReason!, selectedTime)
                dismiss()
            }
        } label: {
            Text("Defer")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func todayAt(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
    }

    private func tomorrowAt(hour: Int) -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        return Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}

struct TimeOptionButton: View {
    let title: String
    let time: Date?
    let onSelect: (Date?) -> Void

    var body: some View {
        Button {
            HapticEngine.shared.lightTap()
            onSelect(time)
        } label: {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
