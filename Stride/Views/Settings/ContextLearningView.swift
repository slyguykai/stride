import SwiftUI

/// View for viewing and editing learned personal context
struct ContextLearningView: View {
    @State private var contextEntries: [PersonalContextEntry] = []
    @State private var statistics: ContextStatistics?
    @State private var showAddEntry = false
    @State private var selectedEntry: PersonalContextEntry?
    @State private var isLoading = true
    
    private let contextEngine: ContextEngine
    
    init(contextEngine: ContextEngine = ContextEngine()) {
        self.contextEngine = contextEngine
    }
    
    var body: some View {
        List {
            statisticsSection
            
            if !contextEntries.isEmpty {
                learnedContextSection
            }
            
            insightsSection
        }
        .navigationTitle("Learned Context")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddEntry = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddContextEntrySheet { entry in
                _Concurrency.Task {
                    await contextEngine.updatePersonalContext(entry)
                    await loadContext()
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EditContextEntrySheet(entry: entry) { updated in
                _Concurrency.Task {
                    if let updated {
                        await contextEngine.updatePersonalContext(updated)
                    } else {
                        await contextEngine.deletePersonalContext(entry)
                    }
                    await loadContext()
                }
            }
        }
        .task {
            await loadContext()
        }
        .refreshable {
            await loadContext()
        }
    }
    
    private var statisticsSection: some View {
        Section("Learning Statistics") {
            if let stats = statistics {
                LabeledContent("Behavior Recordings", value: "\(stats.totalRecordings)")
                LabeledContent("Completion Rate", value: "\(Int(stats.overallCompletionRate * 100))%")
                
                if !stats.bestHours.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best Hours")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(stats.bestHours.map { formatHour($0) }.joined(separator: ", "))
                            .font(.subheadline)
                    }
                }
                
                LabeledContent("Personal Context Items", value: "\(stats.personalContextCount)")
            } else if isLoading {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("No data collected yet")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var learnedContextSection: some View {
        Section("Learned About You") {
            ForEach(groupedEntries.keys.sorted(), id: \.self) { category in
                DisclosureGroup(category.capitalized) {
                    ForEach(groupedEntries[category] ?? []) { entry in
                        ContextEntryRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedEntry = entry
                            }
                    }
                }
            }
        }
    }
    
    private var insightsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("How Learning Works", systemImage: "brain.head.profile")
                    .font(.headline)
                
                Text("Stride learns from your patterns:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    InsightRow(icon: "clock", text: "When you complete different task types")
                    InsightRow(icon: "bolt.fill", text: "Your energy patterns throughout the day")
                    InsightRow(icon: "building.2", text: "Vendors and services you use")
                    InsightRow(icon: "calendar", text: "Preferred days for activities")
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var groupedEntries: [String: [PersonalContextEntry]] {
        Dictionary(grouping: contextEntries) { $0.category }
    }
    
    private func loadContext() async {
        isLoading = true
        contextEntries = await contextEngine.getPersonalContext()
        statistics = await contextEngine.getStatistics()
        isLoading = false
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

struct ContextEntryRow: View {
    let entry: PersonalContextEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.key.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                
                Text(entry.value)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ConfidenceIndicator(confidence: entry.confidence)
                
                if entry.isUserEdited {
                    Text("Edited")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConfidenceIndicator: View {
    let confidence: Float
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < confidenceLevel ? Color.green : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var confidenceLevel: Int {
        switch confidence {
        case 0..<0.4: return 1
        case 0.4..<0.7: return 2
        default: return 3
        }
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct AddContextEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let onSave: (PersonalContextEntry) -> Void
    
    @State private var category = "preference"
    @State private var key = ""
    @State private var value = ""
    
    private let categories = ["preference", "vendor", "timing", "habit"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat.capitalized)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    TextField("Key (e.g., favorite_grocery)", text: $key)
                    TextField("Value (e.g., Whole Foods)", text: $value)
                }
                
                Section {
                    Text("Add context that Stride should know about you. This helps personalize suggestions.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let entry = PersonalContextEntry(
                            category: category,
                            key: key,
                            value: value,
                            confidence: 1.0,
                            occurrences: 1,
                            isUserEdited: true
                        )
                        onSave(entry)
                        dismiss()
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
        }
    }
}

struct EditContextEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let entry: PersonalContextEntry
    let onSave: (PersonalContextEntry?) -> Void
    
    @State private var key: String
    @State private var value: String
    @State private var showDeleteConfirmation = false
    
    init(entry: PersonalContextEntry, onSave: @escaping (PersonalContextEntry?) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _key = State(initialValue: entry.key)
        _value = State(initialValue: entry.value)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Key", text: $key)
                    TextField("Value", text: $value)
                }
                
                Section("Statistics") {
                    LabeledContent("Category", value: entry.category.capitalized)
                    LabeledContent("Occurrences", value: "\(entry.occurrences)")
                    LabeledContent("Confidence", value: "\(Int(entry.confidence * 100))%")
                    LabeledContent("Last Seen", value: entry.lastSeen.formatted(date: .abbreviated, time: .omitted))
                }
                
                Section {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
            }
            .navigationTitle("Edit Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = PersonalContextEntry(
                            category: entry.category,
                            key: key,
                            value: value,
                            confidence: entry.confidence,
                            occurrences: entry.occurrences,
                            isUserEdited: true
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
            .confirmationDialog("Delete Context?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    onSave(nil)
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContextLearningView()
    }
}

