import Foundation

@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()

    private init() {}
}
