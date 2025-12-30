import XCTest
import SwiftData
@testable import Stride

final class TaskRepositoryTests: XCTestCase {
    func testTaskCRUD() async throws {
        let container = try ModelContainerFactory.makeContainer(inMemory: true)
        let repository = TaskRepository(modelContainer: container)

        let task = Task(
            rawInput: "buy groceries",
            title: "Buy groceries",
            energyLevel: .low,
            estimatedMinutes: 15,
            status: .active,
            taskType: .obligation
        )

        try await repository.save(task)

        let fetched = try await repository.fetch(id: task.id)
        XCTAssertEqual(fetched?.title, "Buy groceries")

        let all = try await repository.fetchAll()
        XCTAssertEqual(all.count, 1)

        try await repository.delete(task)
        let afterDelete = try await repository.fetchAll()
        XCTAssertTrue(afterDelete.isEmpty)
    }
}
