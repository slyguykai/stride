import CoreHaptics
import UIKit

/// Centralized haptic feedback engine with patterns for all app interactions
/// 
/// ## Haptic Mapping (Phase 8)
/// | Action | Pattern |
/// |--------|---------|
/// | Swipe gesture threshold | Light impact |
/// | Scroll snap | Soft impact |
/// | Defer tap | Medium impact |
/// | Card expand | Selection change |
/// | Complete task | Success notification + custom pattern |
/// | Error/warning | Error notification |
/// | Focus time start | Heavy impact |
/// | Subtask toggle | Light impact |
/// | Scope creep warning | Warning notification |
@MainActor
final class HapticEngine {
    static let shared = HapticEngine()

    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool { CHHapticEngine.capabilitiesForHardware().supportsHaptics }

    private init() {
        prepareEngine()
    }

    private func prepareEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { [weak self] _ in
                self?.prepareEngine()
            }
        } catch {
            // Fall back to UIFeedbackGenerator if needed.
        }
    }
    
    // MARK: - Basic Impacts

    /// Light tap - swipe thresholds, subtask toggle
    func lightTap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    /// Soft tap - scroll snap, minor interactions
    func softTap() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// Medium tap - defer actions, button presses
    func mediumTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Heavy tap - focus time start, major actions
    func heavyTap() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    /// Rigid tap - high-intensity feedback
    func rigidTap() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    // MARK: - Selection
    
    /// Selection changed - card expand, picker changes
    func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    // MARK: - Notifications

    /// Success - task completion, positive outcomes
    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    /// Warning - scope creep, approaching limits
    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    
    /// Error - failed actions, invalid input
    func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    // MARK: - Custom Patterns

    /// Task completion - satisfying double-tap pattern
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
    
    /// Focus time start - building anticipation pattern
    func focusTimeStart() {
        guard let engine else {
            heavyTap()
            return
        }
        do {
            // Build up pattern: soft -> medium -> heavy
            let events: [CHHapticEvent] = [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0.08
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0.16
                )
            ]

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            heavyTap()
        }
    }
    
    /// Cascade effect - ripple pattern for unblocking multiple tasks
    func cascadeEffect(count: Int) {
        guard let engine, count > 0 else {
            if count > 0 { success() }
            return
        }
        do {
            let eventCount = min(count, 5) // Cap at 5 taps
            var events: [CHHapticEvent] = []
            
            for i in 0..<eventCount {
                let intensity = 0.8 - (Double(i) * 0.1)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: Double(i) * 0.08
                )
                events.append(event)
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            success()
        }
    }
    
    /// Scope creep warning - subtle rumble
    func scopeCreepWarning() {
        guard let engine else {
            warning()
            return
        }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.3
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            warning()
        }
    }
}
