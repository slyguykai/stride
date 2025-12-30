import SwiftUI

struct SwipeableCard<Content: View>: View {
    let content: Content
    let onSwipeRight: () async -> Void
    let onSwipeLeft: () -> Void

    @State private var offset: CGFloat = 0
    @State private var didTriggerHaptic = false
    private let threshold: CGFloat = 100

    init(
        @ViewBuilder content: () -> Content,
        onSwipeRight: @escaping () async -> Void,
        onSwipeLeft: @escaping () -> Void
    ) {
        self.content = content()
        self.onSwipeRight = onSwipeRight
        self.onSwipeLeft = onSwipeLeft
    }

    var body: some View {
        ZStack {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green)
                    .opacity(offset > 0 ? min(offset / threshold, 1) : 0)

                Spacer()

                Image(systemName: "clock.arrow.circlepath")
                    .font(.title)
                    .foregroundStyle(.orange)
                    .opacity(offset < 0 ? min(-offset / threshold, 1) : 0)
            }
            .padding(.horizontal, 20)

            content
                .offset(x: offset)
                .gesture(dragGesture)
        }
        .animation(Animation.strideSpringResponsive, value: offset)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
                let passed = abs(value.translation.width) > threshold
                if passed, !didTriggerHaptic {
                    // Light tap when crossing threshold
                    HapticEngine.shared.lightTap()
                    didTriggerHaptic = true
                } else if !passed {
                    didTriggerHaptic = false
                }
            }
            .onEnded { value in
                if value.translation.width > threshold {
                    // Complete - success pattern is handled in viewModel.complete()
                    offset = UIScreen.main.bounds.width
                    _Concurrency.Task { await onSwipeRight() }
                } else if value.translation.width < -threshold {
                    // Defer - medium tap
                    HapticEngine.shared.mediumTap()
                    onSwipeLeft()
                    offset = 0
                } else {
                    // Cancelled swipe - soft snap back
                    HapticEngine.shared.softTap()
                    offset = 0
                }
                didTriggerHaptic = false
            }
    }
}
