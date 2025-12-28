import SwiftUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = CaptureViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.rawInput.isEmpty {
                rawInputSection
            }

            Spacer()

            if viewModel.isProcessing {
                processingView
            }

            if let parsed = viewModel.parsedTask {
                ParsedTaskEditor(parsed: parsed) { edited in
                    _Concurrency.Task { await viewModel.acceptTask(edited) }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()

            inputArea
        }
        .padding(.top)
        .onAppear {
            viewModel.configure(modelContext: modelContext)
            isInputFocused = true
        }
        .navigationTitle("Capture")
    }

    private var rawInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your thought")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(viewModel.rawInput)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Understanding your thought...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("What's on your mind?", text: $viewModel.input, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isInputFocused)
                .lineLimit(1...5)

            Button {
                viewModel.startVoiceCapture()
            } label: {
                Image(systemName: viewModel.isRecording ? "waveform" : "mic.fill")
                    .font(.title2)
                    .symbolEffect(.pulse, isActive: viewModel.isRecording)
            }

            Button {
                _Concurrency.Task { await viewModel.submit() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
            }
            .disabled(viewModel.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

#Preview {
    NavigationStack {
        CaptureView()
    }
}
