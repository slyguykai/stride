import Foundation

enum DependencyError: Error {
    case cycleDetected
}

actor DependencyGraphEngine {
    private var blockedBy: [UUID: Set<UUID>] = [:]
    private var blocks: [UUID: Set<UUID>] = [:]

    func addDependency(blocker: UUID, blocked: UUID) throws {
        if wouldCreateCycle(from: blocked, to: blocker) {
            throw DependencyError.cycleDetected
        }
        blockedBy[blocked, default: []].insert(blocker)
        blocks[blocker, default: []].insert(blocked)
    }

    func removeDependency(blocker: UUID, blocked: UUID) {
        blockedBy[blocked]?.remove(blocker)
        blocks[blocker]?.remove(blocked)
    }

    func getBlockers(for taskId: UUID) -> Set<UUID> {
        blockedBy[taskId] ?? []
    }

    func getBlocked(by taskId: UUID) -> Set<UUID> {
        blocks[taskId] ?? []
    }

    func isActionable(_ taskId: UUID) -> Bool {
        blockedBy[taskId]?.isEmpty ?? true
    }

    func completeTask(_ taskId: UUID) -> Set<UUID> {
        var newlyUnblocked: Set<UUID> = []
        for blockedId in blocks[taskId] ?? [] {
            blockedBy[blockedId]?.remove(taskId)
            if blockedBy[blockedId]?.isEmpty ?? true {
                newlyUnblocked.insert(blockedId)
            }
        }
        blocks.removeValue(forKey: taskId)
        blockedBy.removeValue(forKey: taskId)
        return newlyUnblocked
    }

    private func wouldCreateCycle(from start: UUID, to end: UUID) -> Bool {
        var visited: Set<UUID> = []
        var stack: [UUID] = [start]

        while let current = stack.popLast() {
            if current == end { return true }
            if visited.contains(current) { continue }
            visited.insert(current)
            stack.append(contentsOf: blocks[current] ?? [])
        }

        return false
    }
}
