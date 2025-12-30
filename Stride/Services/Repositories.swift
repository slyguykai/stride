import Foundation
import SwiftData

protocol TaskRepositoryProtocol {
    func fetchAll() async throws -> [Task]
    func fetch(id: UUID) async throws -> Task?
    func save(_ task: Task) async throws
    func delete(_ task: Task) async throws
}

@ModelActor
actor TaskRepository: TaskRepositoryProtocol {
    func fetchAll() async throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\Task.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> Task? {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ task: Task) async throws {
        modelContext.insert(task)
        try modelContext.save()
    }

    func delete(_ task: Task) async throws {
        modelContext.delete(task)
        try modelContext.save()
    }
}

protocol SubtaskRepositoryProtocol {
    func fetchAll() async throws -> [Subtask]
    func fetch(id: UUID) async throws -> Subtask?
    func save(_ subtask: Subtask) async throws
    func delete(_ subtask: Subtask) async throws
}

@ModelActor
actor SubtaskRepository: SubtaskRepositoryProtocol {
    func fetchAll() async throws -> [Subtask] {
        let descriptor = FetchDescriptor<Subtask>(
            sortBy: [SortDescriptor(\Subtask.order, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> Subtask? {
        let descriptor = FetchDescriptor<Subtask>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ subtask: Subtask) async throws {
        modelContext.insert(subtask)
        try modelContext.save()
    }

    func delete(_ subtask: Subtask) async throws {
        modelContext.delete(subtask)
        try modelContext.save()
    }
}

protocol TaskDependencyRepositoryProtocol {
    func fetchAll() async throws -> [TaskDependency]
    func fetch(id: UUID) async throws -> TaskDependency?
    func save(_ dependency: TaskDependency) async throws
    func delete(_ dependency: TaskDependency) async throws
}

@ModelActor
actor TaskDependencyRepository: TaskDependencyRepositoryProtocol {
    func fetchAll() async throws -> [TaskDependency] {
        let descriptor = FetchDescriptor<TaskDependency>()
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> TaskDependency? {
        let descriptor = FetchDescriptor<TaskDependency>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ dependency: TaskDependency) async throws {
        modelContext.insert(dependency)
        try modelContext.save()
    }

    func delete(_ dependency: TaskDependency) async throws {
        modelContext.delete(dependency)
        try modelContext.save()
    }
}

protocol DeferEventRepositoryProtocol {
    func fetchAll() async throws -> [DeferEvent]
    func fetch(id: UUID) async throws -> DeferEvent?
    func save(_ event: DeferEvent) async throws
    func delete(_ event: DeferEvent) async throws
}

@ModelActor
actor DeferEventRepository: DeferEventRepositoryProtocol {
    func fetchAll() async throws -> [DeferEvent] {
        let descriptor = FetchDescriptor<DeferEvent>(
            sortBy: [SortDescriptor(\DeferEvent.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> DeferEvent? {
        let descriptor = FetchDescriptor<DeferEvent>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ event: DeferEvent) async throws {
        modelContext.insert(event)
        try modelContext.save()
    }

    func delete(_ event: DeferEvent) async throws {
        modelContext.delete(event)
        try modelContext.save()
    }
}

protocol UserPatternRepositoryProtocol {
    func fetchAll() async throws -> [UserPattern]
    func fetch(id: UUID) async throws -> UserPattern?
    func save(_ pattern: UserPattern) async throws
    func delete(_ pattern: UserPattern) async throws
}

@ModelActor
actor UserPatternRepository: UserPatternRepositoryProtocol {
    func fetchAll() async throws -> [UserPattern] {
        let descriptor = FetchDescriptor<UserPattern>()
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> UserPattern? {
        let descriptor = FetchDescriptor<UserPattern>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func save(_ pattern: UserPattern) async throws {
        modelContext.insert(pattern)
        try modelContext.save()
    }

    func delete(_ pattern: UserPattern) async throws {
        modelContext.delete(pattern)
        try modelContext.save()
    }
}
