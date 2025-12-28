import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Notifications") {
                NavigationLink("Preferences") {
                    NotificationPreferencesView()
                }
            }

            Section("Calendar") {
                NavigationLink("Integration") {
                    CalendarIntegrationView()
                }
            }
        }
        .navigationTitle("Settings")
    }
}
