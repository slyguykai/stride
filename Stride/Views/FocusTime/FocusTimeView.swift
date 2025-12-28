import SwiftUI
import SwiftData

struct FocusTimeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FocusTimeViewModel

    init(candidate: FocusTimeCandidate, modelContext: ModelContext) {
        _viewModel = State(initialValue: FocusTimeViewModel(candidate: candidate, modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    TaskCard(task: viewModel.candidate.task, size: .medium)
                        .allowsHitTesting(false)

                    triggerSection
                    downstreamImpactSection
                    microBreakdownSection
                    availabilitySection
                    actionSection
                }
                .padding()
            }
            .navigationTitle("Focus Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var triggerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.candidate.trigger.title)
                .font(.headline)
            Text(viewModel.candidate.trigger.prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var downstreamImpactSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Downstream impact")
                .font(.headline)

            if viewModel.blockedTasks.isEmpty {
                Text("No tasks are currently blocked by this.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.blockedTasks) { task in
                    HStack {
                        Image(systemName: "arrow.turn.down.right")
                            .foregroundStyle(.orange)
                        Text(task.title)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var microBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Micro-breakdown")
                .font(.headline)

            TextField("What's blocking you?", text: $viewModel.blockReason, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Button("Refresh suggestions") {
                _Concurrency.Task {
                    await viewModel.regenerateMicroBreakdown()
                }
            }
            .font(.subheadline)

            if viewModel.isLoading {
                ProgressView("Finding a tiny first step...")
            } else if let breakdown = viewModel.microBreakdown {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(breakdown.microSteps, id: \.self) { step in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .padding(.top, 6)
                            Text(step)
                        }
                        .font(.subheadline)
                    }

                    Text("Simplified: \(breakdown.simplifiedVersion)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if !breakdown.missingInfo.isEmpty {
                        Text("Missing info: \(breakdown.missingInfo)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No micro-breakdown available right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var availabilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested time slots")
                .font(.headline)

            if viewModel.availableSlots.isEmpty {
                Text("No free time detected in the next week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.availableSlots.prefix(3), id: \.self) { slot in
                    Button {
                        viewModel.selectedSlot = slot
                    } label: {
                        HStack {
                            Text(slot.formatted(date: .abbreviated, time: .shortened))
                            Spacer()
                            if viewModel.selectedSlot == slot {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
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
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.addMicroStepsToTask()
            } label: {
                Text("Add micro-steps to task")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.microBreakdown == nil)

            Button {
                viewModel.commitToSlot()
                AudioManager.shared.play(.focusStart)
                HapticEngine.shared.success()
                dismiss()
            } label: {
                Text("Commit to selected time")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(viewModel.selectedSlot == nil)

            Button {
                viewModel.markNotDoing()
                dismiss()
            } label: {
                Text("Mark as not doing")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

#Preview {
    let task = Task(
        rawInput: "order contacts",
        title: "Order contacts from 1-800 Contacts",
        energyLevel: .low,
        estimatedMinutes: 10,
        status: .active,
        taskType: .obligation
    )
    return FocusTimeView(
        candidate: FocusTimeCandidate(task: task, trigger: .deferredStreak),
        modelContext: ModelContext(try! ModelContainerFactory.makeContainer(inMemory: true))
    )
}
