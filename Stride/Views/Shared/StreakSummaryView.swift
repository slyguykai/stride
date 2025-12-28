import SwiftUI

struct StreakSummaryView: View {
    let data: StreakData

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(data.tasksToday) tasks")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(data.currentDayStreak) days")
                    .font(.headline)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Weekly avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f", data.weeklyAverage))
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
