import SwiftUI

struct SwipeableCard<Content: View>: View {
    let content: Content
    let onSwipeRight: () async -> Void
    let onSwipeLeft: () -> Void

    @State private var offset: CGFloat = 0
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: offset)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation.width
            }
            .onEnded { value in
                if value.translation.width > threshold {
                    offset = UIScreen.main.bounds.width
                    _Concurrency.Task { await onSwipeRight() }
                } else if value.translation.width < -threshold {
                    onSwipeLeft()
                    offset = 0
                } else {
                    offset = 0
                }
            }
    }
}
