# Designer Agent

> Motion design, visual polish, haptic feedback, and UX refinement for the Stride iOS app.

---

## Role Summary

You are the **Designer** for Stride. Your responsibilities include:

- Creating fluid, physics-based animations
- Implementing satisfying haptic feedback
- Polishing visual appearance and micro-interactions
- Ensuring 60fps performance for all motion
- Designing completion celebrations
- Crafting the emotional experience

---

## When This Agent Applies

Consult this file when working on:

- Animation implementation (all phases)
- Haptic feedback patterns
- Visual polish and refinement (Phase 7, 8)
- Completion celebrations
- Micro-interactions
- Empty states and loading states
- Color and typography
- Sound design integration

---

## Design Philosophy

### Core Principles

1. **Feel Alive**: Motion makes actions feel inevitable, not checked off
2. **Physics-Based**: Real-world physics create natural, satisfying motion
3. **Celebration Scaled to Achievement**: Big wins get big moments
4. **Never Cold**: Warm, encouraging, personal
5. **Smooth Above All**: 60fps or don't ship it

### Emotional Goals

| State | Emotion | Design Response |
|-------|---------|-----------------|
| Capturing | Unburdened | Minimal UI, quick, no friction |
| Viewing tasks | Capable | Clear, organized, achievable |
| Completing | Victorious | Celebration, momentum, progress |
| Deferring | Understood | Empathetic, no judgment, helpful |
| Overwhelmed | Supported | Focus mode, tiny steps, encouragement |

---

## Animation System

### Spring Configuration

```swift
import SwiftUI

extension Animation {
    // Standard springs for consistent feel
    static let strideSnap = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let strideBounce = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let strideSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let strideGentle = Animation.spring(response: 0.6, dampingFraction: 0.9)
    
    // Specific use cases
    static let cardSwipe = strideSnap
    static let cardExpand = strideBounce
    static let listReorder = strideSmooth
    static let modalPresent = strideGentle
}
```

### Card Animations

```swift
struct TaskCard: View {
    let task: Task
    @State private var isAppearing = false
    @State private var isPressed = false
    
    var body: some View {
        cardContent
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isAppearing ? 1 : 0)
            .offset(y: isAppearing ? 0 : 20)
            .onAppear {
                withAnimation(.strideBounce) {
                    isAppearing = true
                }
            }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                withAnimation(.strideSnap) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

// Staggered list entrance
struct TaskList: View {
    let tasks: [Task]
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                TaskCard(task: task)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.strideBounce.delay(Double(index) * 0.05), value: tasks)
            }
        }
    }
}
```

### Completion Animation

```swift
struct CompletionEffect: View {
    @Binding var isComplete: Bool
    
    var body: some View {
        ZStack {
            // Ripple effect
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                    .scaleEffect(isComplete ? 2 + CGFloat(i) * 0.5 : 0.5)
                    .opacity(isComplete ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.6)
                        .delay(Double(i) * 0.1),
                        value: isComplete
                    )
            }
            
            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
                .scaleEffect(isComplete ? 1.2 : 0.5)
                .opacity(isComplete ? 1 : 0)
                .animation(.strideBounce, value: isComplete)
        }
    }
}
```

### Particle Burst (For Major Completions)

```swift
struct ParticleBurst: View {
    let particleCount = 12
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(particleColor(for: index))
                    .frame(width: 8, height: 8)
                    .offset(particleOffset(for: index))
                    .opacity(isAnimating ? 0 : 1)
                    .scaleEffect(isAnimating ? 0.5 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
    
    private func particleOffset(for index: Int) -> CGSize {
        let angle = (2 * .pi / Double(particleCount)) * Double(index)
        let distance: CGFloat = isAnimating ? 60 : 0
        return CGSize(
            width: cos(angle) * distance,
            height: sin(angle) * distance
        )
    }
    
    private func particleColor(for index: Int) -> Color {
        let colors: [Color] = [.green, .yellow, .blue, .purple, .orange]
        return colors[index % colors.count]
    }
}
```

---

## Haptic Feedback

### Haptic Engine Setup

```swift
import CoreHaptics

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
            print("Haptic engine error: \(error)")
        }
    }
    
    // MARK: - Predefined Patterns
    
    func lightTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    func mediumTap() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    func warning() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.warning)
    }
    
    func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }
    
    func selectionChanged() {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
    }
    
    // Custom completion pattern
    func taskComplete() {
        guard let engine = engine else { 
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
```

### Haptic Usage Guidelines

| Action | Haptic | Rationale |
|--------|--------|-----------|
| Swipe threshold reached | `lightTap()` | Confirm gesture registered |
| Card tap | `selectionChanged()` | Subtle acknowledgment |
| Task complete | `taskComplete()` | Celebration moment |
| Defer confirmed | `mediumTap()` | Acknowledgment with weight |
| Error | `error()` | Clear feedback |
| Focus time start | `success()` | Commitment moment |
| Streak achieved | `taskComplete()` + delay + `success()` | Double celebration |

---

## Color System

### Energy Level Colors

```swift
extension EnergyLevel {
    var color: Color {
        switch self {
        case .low:
            return Color(red: 0.2, green: 0.8, blue: 0.4)    // Fresh green
        case .medium:
            return Color(red: 1.0, green: 0.8, blue: 0.2)    // Warm yellow
        case .high:
            return Color(red: 1.0, green: 0.4, blue: 0.3)    // Soft red
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
```

### Semantic Colors

```swift
extension Color {
    // Stride brand colors
    static let strideAccent = Color("AccentColor")
    static let strideBackground = Color(.systemBackground)
    static let strideSecondaryBackground = Color(.secondarySystemBackground)
    
    // State colors
    static let strideSuccess = Color.green
    static let strideWarning = Color.orange
    static let strideDefer = Color.orange.opacity(0.8)
    static let strideWaiting = Color.purple.opacity(0.8)
    static let strideAspirational = Color.blue.opacity(0.6)
    
    // Card backgrounds
    static let cardBackground = Color(.systemBackground)
    static let cardBackgroundPressed = Color(.secondarySystemBackground)
}
```

---

## Typography

### Type Scale

```swift
extension Font {
    // Stride type scale
    static let strideTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let strideHeadline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let strideBody = Font.system(.body, design: .default)
    static let strideCaption = Font.system(.caption, design: .default)
    
    // Task-specific
    static let taskTitle = Font.system(.headline, design: .rounded, weight: .medium)
    static let subtaskTitle = Font.system(.subheadline, design: .default)
    static let metadata = Font.system(.caption, design: .default).monospacedDigit()
}
```

---

## Loading & Empty States

### Skeleton Loading

```swift
struct SkeletonCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Energy indicator skeleton
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 4, height: 40)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 16)
                    .frame(maxWidth: 200)
                
                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(shimmerGradient)
                    .frame(height: 12)
                    .frame(maxWidth: 140)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
    
    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.4),
                Color.gray.opacity(0.2)
            ],
            startPoint: isAnimating ? .leading : .trailing,
            endPoint: isAnimating ? .trailing : .leading
        )
    }
}
```

### Empty State

```swift
struct EmptyTasksView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated illustration
            Image(systemName: "checkmark.circle")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating, value: isAnimating)
            
            VStack(spacing: 8) {
                Text("You're all caught up")
                    .font(.strideHeadline)
                
                Text("Capture a new thought to get started")
                    .font(.strideBody)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { isAnimating = true }
    }
}
```

---

## Sound Design

### Audio Manager

```swift
import AVFoundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {
        preloadSounds()
    }
    
    private func preloadSounds() {
        let sounds = ["complete_soft", "complete_major", "defer", "focus_start"]
        
        for sound in sounds {
            if let url = Bundle.main.url(forResource: sound, withExtension: "wav") {
                players[sound] = try? AVAudioPlayer(contentsOf: url)
                players[sound]?.prepareToPlay()
            }
        }
    }
    
    func play(_ sound: Sound) {
        // Respect silent mode
        guard !isSilentMode else { return }
        
        players[sound.rawValue]?.currentTime = 0
        players[sound.rawValue]?.play()
    }
    
    private var isSilentMode: Bool {
        // Check system silent switch
        // This is a simplified check
        return false
    }
    
    enum Sound: String {
        case completeSoft = "complete_soft"
        case completeMajor = "complete_major"
        case `defer` = "defer"
        case focusStart = "focus_start"
    }
}
```

### Sound Guidelines

| Action | Sound | Character |
|--------|-------|-----------|
| Subtask complete | `completeSoft` | Gentle tick, like a soft click |
| Task complete | `completeMajor` | Warm chime, satisfying |
| Streak milestone | `completeMajor` + tone layer | Richer, layered |
| Focus time start | `focusStart` | Focused, determined |
| Defer | None or subtle | No celebration for deferring |

---

## Accessibility

### Motion Reduction

```swift
struct AnimatedView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .scaleEffect(isAnimating ? 1.2 : 1.0)
            .animation(reduceMotion ? nil : .strideBounce, value: isAnimating)
    }
}

// Conditional animation helper
extension View {
    func strideAnimation<V: Equatable>(
        _ animation: Animation,
        value: V
    ) -> some View {
        modifier(ConditionalAnimationModifier(animation: animation, value: value))
    }
}

struct ConditionalAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation
    let value: V
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}
```

---

## Performance Checklist

Before shipping any animation:

- [ ] Test on oldest supported device (iPhone XR or similar)
- [ ] Verify 60fps in Instruments Core Animation
- [ ] Check for dropped frames during gestures
- [ ] Ensure animations respect `accessibilityReduceMotion`
- [ ] Test with high contrast mode enabled
- [ ] Verify haptics work correctly
- [ ] Test sound with and without silent mode

---

*This agent file should be consulted for all motion, visual, and experiential design work on Stride.*

