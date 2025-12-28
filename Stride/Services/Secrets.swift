import Foundation

enum Secrets {
    static var openAIKey: String? {
        if let env = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !env.isEmpty {
            return env
        }
        let infoValue = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String
        if let infoValue, !infoValue.isEmpty {
            return infoValue
        }
        return nil
    }
}
