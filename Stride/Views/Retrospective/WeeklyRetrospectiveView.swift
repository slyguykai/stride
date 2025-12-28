import SwiftUI
import SwiftData

struct WeeklyRetrospectiveView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RetrospectiveViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                completedSection
                timeByTypeSection
                deferPatternsSection
                cascadeSection
                encouragementSection
            }
            .padding()
        }
        .navigationTitle("Weekly Review")
        .onAppear {
            if viewModel == nil {
                viewModel = RetrospectiveViewModel(modelContext: modelContext)
            }
            viewModel?.load()
        }
        .refreshable {
            viewModel?.load()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This week")
                .font(.headline)
            Text("\(viewModel?.completedTasks.count ?? 0) tasks completed")
                .font(.title2.bold())
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Completed by type")
                .font(.headline)
            ForEach(TaskType.allCases, id: \.self) { type in
                let count = viewModel?.completedByType[type] ?? 0
                if count > 0 {
                    HStack {
                        Text(type.rawValue.capitalized)
                        Spacer()
                        Text("\(count)")
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var timeByTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated time invested")
                .font(.headline)
            ForEach(TaskType.allCases, id: \.self) { type in
                let minutes = viewModel?.minutesByType[type] ?? 0
                if minutes > 0 {
                    HStack {
                        Text(type.rawValue.capitalized)
                        Spacer()
                        Text("\(minutes) min")
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var deferPatternsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Defer patterns")
                .font(.headline)
            if let reasons = viewModel?.deferReasons, !reasons.isEmpty {
                ForEach(reasons.keys.sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { reason in
                    HStack {
                        Text(reason.title)
                        Spacer()
                        Text("\(reasons[reason] ?? 0)")
                    }
                    .font(.subheadline)
                }
            } else {
                Text("No defers logged this week.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var cascadeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cascade effects")
                .font(.headline)
            Text("Unblocked dependencies: \(viewModel?.cascadeCount ?? 0)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var encouragementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Encouragement")
                .font(.headline)
            Text(viewModel?.encouragement ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
