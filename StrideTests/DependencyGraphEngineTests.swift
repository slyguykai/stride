import XCTest
@testable import Stride

final class DependencyGraphEngineTests: XCTestCase {
    func testAddDependencyAndQuery() async throws {
        let engine = DependencyGraphEngine()
        let taskA = UUID()
        let taskB = UUID()

        try await engine.addDependency(blocker: taskA, blocked: taskB)

        let blockers = await engine.getBlockers(for: taskB)
        let isActionable = await engine.isActionable(taskB)
        XCTAssertEqual(blockers, [taskA])
        XCTAssertFalse(isActionable)
    }

    func testDetectsCycle() async {
        let engine = DependencyGraphEngine()
        let taskA = UUID()
        let taskB = UUID()

        try? await engine.addDependency(blocker: taskA, blocked: taskB)

        do {
            try await engine.addDependency(blocker: taskB, blocked: taskA)
            XCTFail("Expected cycle detection to throw")
        } catch {
            XCTAssertTrue(error is DependencyError)
        }
    }

    func testCompleteTaskUnblocksDependents() async throws {
        let engine = DependencyGraphEngine()
        let blocker = UUID()
        let blocked = UUID()

        try await engine.addDependency(blocker: blocker, blocked: blocked)
        let newlyUnblocked = await engine.completeTask(blocker)
        let isActionable = await engine.isActionable(blocked)

        XCTAssertEqual(newlyUnblocked, [blocked])
        XCTAssertTrue(isActionable)
    }
}
