import EventKit
import Foundation

struct FreeBusyAnalysis {
    let busy: [DateInterval]
    let free: [DateInterval]
}

protocol CalendarServiceProtocol: Sendable {
    func authorizationStatus() -> EKAuthorizationStatus
    func requestAccess() async -> Bool
    func fetchEvents(from start: Date, to end: Date) async throws -> [EKEvent]
    func analyzeFreeBusy(from start: Date, to end: Date, minFreeMinutes: Int) async throws -> FreeBusyAnalysis
    func nextAvailableSlots(durationMinutes: Int, searchDays: Int) async throws -> [Date]
}

actor CalendarService: CalendarServiceProtocol {
    private let store = EKEventStore()

    nonisolated func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestAccess(to: .event)
        } catch {
            return false
        }
    }

    func fetchEvents(from start: Date, to end: Date) async throws -> [EKEvent] {
        let status = authorizationStatus()
        guard status == .authorized || status == .fullAccess else {
            return []
        }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
    }

    func analyzeFreeBusy(from start: Date, to end: Date, minFreeMinutes: Int) async throws -> FreeBusyAnalysis {
        let events = try await fetchEvents(from: start, to: end)
        let busyIntervals = mergeIntervals(events.map { DateInterval(start: $0.startDate, end: $0.endDate) })
        let freeIntervals = computeFreeIntervals(
            within: DateInterval(start: start, end: end),
            busy: busyIntervals,
            minFreeMinutes: minFreeMinutes
        )
        return FreeBusyAnalysis(busy: busyIntervals, free: freeIntervals)
    }

    func nextAvailableSlots(durationMinutes: Int, searchDays: Int) async throws -> [Date] {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: searchDays, to: start) ?? start
        let analysis = try await analyzeFreeBusy(from: start, to: end, minFreeMinutes: durationMinutes)
        return analysis.free.map(\.start)
    }

    private func mergeIntervals(_ intervals: [DateInterval]) -> [DateInterval] {
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [DateInterval] = []

        for interval in sorted {
            guard let last = merged.last else {
                merged.append(interval)
                continue
            }
            if last.intersects(interval) || last.end == interval.start {
                merged[merged.count - 1] = DateInterval(start: last.start, end: max(last.end, interval.end))
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    private func computeFreeIntervals(
        within window: DateInterval,
        busy: [DateInterval],
        minFreeMinutes: Int
    ) -> [DateInterval] {
        var free: [DateInterval] = []
        var cursor = window.start

        for interval in busy {
            if interval.start > cursor {
                let gap = DateInterval(start: cursor, end: interval.start)
                if gap.duration >= TimeInterval(minFreeMinutes * 60) {
                    free.append(gap)
                }
            }
            cursor = max(cursor, interval.end)
        }

        if cursor < window.end {
            let gap = DateInterval(start: cursor, end: window.end)
            if gap.duration >= TimeInterval(minFreeMinutes * 60) {
                free.append(gap)
            }
        }

        return free
    }
}
