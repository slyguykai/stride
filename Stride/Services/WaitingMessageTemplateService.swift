import Foundation

struct WaitingMessageTemplateService {
    func defaultTemplate(for task: Task, contactName: String?) -> String {
        let name = contactName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name, !name.isEmpty {
            return "Hi \(name), just checking in on \"\(task.title)\". Let me know if you need anything from me."
        }
        return "Just checking in on \"\(task.title)\". Let me know if you need anything from me."
    }
}
