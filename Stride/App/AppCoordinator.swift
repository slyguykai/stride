import SwiftUI

final class AppCoordinator {
    @ViewBuilder
    func rootView() -> some View {
        NavigationStack {
            NowView()
                .navigationTitle("Stride")
        }
    }
}
