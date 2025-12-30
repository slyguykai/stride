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
            
            Section("Learning") {
                NavigationLink("Learned Context") {
                    ContextLearningView()
                }
            }
            
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
            }
        }
        .navigationTitle("Settings")
    }
}
