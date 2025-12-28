import SwiftUI

struct RecurringWindowView: View {
    let rule: RecurringRule

    private var progress: Double {
        let total = rule.windowEnd.timeIntervalSince(rule.windowStart)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(rule.windowStart)
        return min(max(elapsed / total, 0), 1)
    }

    private var remainingText: String {
        let remaining = max(0, rule.windowEnd.timeIntervalSinceNow)
        let days = Int(remaining / 86400)
        if days >= 1 {
            return "\(days)d left"
        }
        let hours = Int(remaining / 3600)
        return "\(max(hours, 1))h left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Window closes: \(rule.windowEnd.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor)
                        .frame(width: proxy.size.width * progress, height: 10)
                }
            }
            .frame(height: 10)

            Text(remainingText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
