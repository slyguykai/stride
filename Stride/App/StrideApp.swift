import SwiftUI
import SwiftData

@main
struct StrideApp: App {
    @State private var coordinator = AppCoordinator()
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainerFactory.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer: \\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            coordinator.rootView()
                .modelContainer(modelContainer)
        }
    }
}
