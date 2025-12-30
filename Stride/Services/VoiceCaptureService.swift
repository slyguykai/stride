import Foundation
import _Concurrency

protocol VoiceCaptureServiceProtocol: Sendable {
    func startTranscription() async throws -> String
    func stopTranscription()
}

final class VoiceCaptureService: VoiceCaptureServiceProtocol {
    func startTranscription() async throws -> String {
        try await _Concurrency.Task.sleep(nanoseconds: 500_000_000)
        return "Review quarterly budget notes"
    }

    func stopTranscription() {}
}
