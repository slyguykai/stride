import SwiftUI

struct AspirationalSectionView: View {
    let tasks: [Task]
    let onSelect: (Task) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Aspirational")
                    .font(.headline)
                Spacer()
                Text("Optional")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if tasks.isEmpty {
                Text("No aspirational tasks yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tasks.prefix(3)) { task in
                    TaskCard(task: task, size: .small) {
                        onSelect(task)
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
