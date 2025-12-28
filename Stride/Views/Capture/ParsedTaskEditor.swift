import SwiftUI

struct ParsedTaskEditor: View {
    @State private var draft: ParsedTask
    let onAccept: (ParsedTask) -> Void

    init(parsed: ParsedTask, onAccept: @escaping (ParsedTask) -> Void) {
        _draft = State(initialValue: parsed)
        self.onAccept = onAccept
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Suggested task")
                .font(.headline)

            TextField("Title", text: $draft.title)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                TextField("Minutes", value: $draft.estimatedMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)

                Picker("Energy", selection: $draft.energyLevel) {
                    ForEach(EnergyLevel.allCases, id: \.self) { level in
                        Text(level.rawValue.capitalized).tag(level)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Subtasks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(draft.subtasks.indices, id: \.self) { index in
                    TextField("Subtask", text: $draft.subtasks[index])
                        .textFieldStyle(.roundedBorder)
                }

                Button("Add subtask") {
                    draft.subtasks.append("")
                }
                .font(.caption)
            }

            Button {
                onAccept(draft)
            } label: {
                Text("Accept")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
