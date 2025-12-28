import SwiftUI
import EventKit

struct CalendarIntegrationView: View {
    @State private var status: EKAuthorizationStatus = CalendarService().authorizationStatus()
    @State private var nextFreeWindow: DateInterval?
    @State private var isLoading = false

    private let calendarService = CalendarService()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calendar access")
                .font(.headline)

            Text(statusDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Request access") {
                _Concurrency.Task {
                    let granted = await calendarService.requestAccess()
                    status = calendarService.authorizationStatus()
                    if granted {
                        await loadAvailability()
                    }
                }
            }

            Divider()

            Text("Free/busy analysis")
                .font(.headline)

            if isLoading {
                ProgressView("Scanning schedule...")
            } else if let nextFreeWindow {
                Text("Next free window: \(formatInterval(nextFreeWindow))")
                    .font(.subheadline)
            } else {
                Text("No free window found in the next 24 hours.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Calendar")
        .task {
            if status == .authorized || status == .fullAccess {
                await loadAvailability()
            }
        }
    }

    private var statusDescription: String {
        switch status {
        case .authorized, .fullAccess:
            return "Access granted."
        case .denied:
            return "Access denied. You can enable it in Settings."
        case .restricted:
            return "Access restricted."
        case .notDetermined:
            return "Not requested."
        case .writeOnly:
            return "Write-only access."
        @unknown default:
            return "Unknown."
        }
    }

    private func loadAvailability() async {
        isLoading = true
        defer { isLoading = false }
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        do {
            let analysis = try await calendarService.analyzeFreeBusy(
                from: start,
                to: end,
                minFreeMinutes: 15
            )
            nextFreeWindow = analysis.free.first
        } catch {
            nextFreeWindow = nil
        }
    }

    private func formatInterval(_ interval: DateInterval) -> String {
        let start = interval.start.formatted(date: .omitted, time: .shortened)
        let end = interval.end.formatted(date: .omitted, time: .shortened)
        return "\(start)-\(end)"
    }
}
