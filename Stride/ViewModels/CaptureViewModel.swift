import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class CaptureViewModel {
    private let aiService: AIServiceProtocol
    private let voiceService: VoiceCaptureServiceProtocol

    private var modelContext: ModelContext?

    var input: String = ""
    var rawInput: String = ""
    var isProcessing = false
    var isRecording = false
    var parsedTask: ParsedTask?
    var errorMessage: String?

    init(
        aiService: AIServiceProtocol? = nil,
        voiceService: VoiceCaptureServiceProtocol = VoiceCaptureService()
    ) {
        if let aiService {
            self.aiService = aiService
        } else if let key = Secrets.openAIKey, !key.isEmpty {
            self.aiService = AIService(apiClient: OpenAIClient())
        } else {
            self.aiService = AIService(apiClient: MockAIClient())
        }
        self.voiceService = voiceService
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func startVoiceCapture() {
        guard !isRecording else {
            stopVoiceCapture()
            return
        }
        isRecording = true
        _Concurrency.Task {
            do {
                let transcript = try await voiceService.startTranscription()
                input = transcript
                isRecording = false
            } catch {
                errorMessage = "Voice capture failed."
                isRecording = false
            }
        }
    }

    func stopVoiceCapture() {
        voiceService.stopTranscription()
        isRecording = false
    }

    func submit() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        rawInput = trimmed
        input = ""
        parsedTask = nil
        errorMessage = nil
        isProcessing = true
        do {
            parsedTask = try await aiService.parseTaskInput(trimmed, context: nil)
        } catch {
            errorMessage = "Could not parse that yet."
        }
        isProcessing = false
    }

    func acceptTask(_ edited: ParsedTask) async {
        guard let modelContext else {
            errorMessage = "Missing model context."
            return
        }
        let service = TaskService(modelContext: modelContext)
        do {
            _ = try await service.createTask(from: edited, rawInput: rawInput)
            parsedTask = nil
            rawInput = ""
        } catch {
            errorMessage = "Could not save task."
        }
    }
}
