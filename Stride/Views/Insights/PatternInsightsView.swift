import SwiftUI
import SwiftData

struct PatternInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var insights: [PatternInsight] = []

    var body: some View {
        List {
            if insights.isEmpty {
                ContentUnavailableView(
                    "No patterns yet",
                    systemImage: "sparkles",
                    description: Text("Complete a few tasks to surface insights.")
                )
            } else {
                ForEach(insights) { insight in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(insight.taskType)
                            .font(.headline)
                        Text(insight.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Label("\(String(format: "%.1f", insight.avgDeferCount)) defers", systemImage: "clock.arrow.circlepath")
                            Spacer()
                        }
                        .font(.caption)

                        if let best = insight.bestTimeOfDay {
                            Text("Best: \(formatHour(best))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let worst = insight.worstTimeOfDay {
                            Text("Hardest: \(formatHour(worst))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if !insight.commonBlockers.isEmpty {
                            Text("Common blocker: \(insight.commonBlockers.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Insights")
        .task {
            loadInsights()
        }
        .refreshable {
            loadInsights()
        }
    }

    private func loadInsights() {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
        )
        let tasks = (try? modelContext.fetch(descriptor)) ?? []
        insights = PatternDetectionService().analyzePatterns(for: tasks)
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}
