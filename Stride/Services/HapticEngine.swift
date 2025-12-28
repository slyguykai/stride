import CoreHaptics
import UIKit

@MainActor
final class HapticEngine {
    static let shared = HapticEngine()

    private var engine: CHHapticEngine?

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            // Fall back to UIFeedbackGenerator if needed.
        }
    }

    func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func mediumTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func taskComplete() {
        guard let engine else {
            success()
            return
        }
        do {
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)

            let event1 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )
            let event2 = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.1
            )

            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            success()
        }
    }
}
