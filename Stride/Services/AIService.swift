import Foundation

protocol AIServiceProtocol: Sendable {
    func parseTaskInput(_ input: String, context: TaskContext?) async throws -> ParsedTask
}

actor AIService: AIServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = OpenAIClient()) {
        self.apiClient = apiClient
    }

    func parseTaskInput(_ input: String, context: TaskContext? = nil) async throws -> ParsedTask {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIServiceError.invalidInput
        }
        let prompt = PromptBuilder.parsingPrompt(input: input, context: context)
        let response = try await apiClient.complete(prompt: prompt)
        let data = Data(response.utf8)
        return try JSONDecoder().decode(ParsedTask.self, from: data)
    }
}

enum AIServiceError: Error {
    case invalidInput
}

protocol APIClientProtocol: Sendable {
    func complete(prompt: String) async throws -> String
}

final class MockAIClient: APIClientProtocol {
    func complete(prompt: String) async throws -> String {
        let parsed = ParsedTask(
            title: "Review shared notes",
            subtasks: ["Open the notes", "Extract action items", "Create tasks"],
            dependencies: [],
            estimatedMinutes: 20,
            energyLevel: .medium,
            contextTags: ["computer"]
        )
        let data = try JSONEncoder().encode(parsed)
        return String(decoding: data, as: UTF8.self)
    }
}

final class OpenAIClient: APIClientProtocol {
    private let apiKey: String?
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.apiKey = Secrets.openAIKey
        self.session = session
    }

    func complete(prompt: String) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw OpenAIClientError.missingApiKey
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = OpenAIChatRequest(
            model: "gpt-4o-mini",
            messages: [
                OpenAIChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.2
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw OpenAIClientError.badResponse
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw OpenAIClientError.emptyResponse
        }
        return content
    }
}

enum OpenAIClientError: Error {
    case missingApiKey
    case badResponse
    case emptyResponse
}

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
    let temperature: Double
}

struct OpenAIChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenAIChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

enum PromptBuilder {
    static func parsingPrompt(input: String, context: TaskContext?) -> String {
        var prompt = """
        You are a task parsing assistant for Stride, a personal productivity app.
        Parse the user's brain dump into structured task data.

        User input: "\(input)"
        """

        if let context, !context.personalContext.isEmpty {
            let contextList = context.personalContext.map { "- \($0.key): \($0.value)" }.joined(separator: "\n")
            prompt += """

            Known personal context:
            \(contextList)
            """
        }

        prompt += """

        Return valid JSON only with:
        {
            "title": "Clear, actionable task title (one sentence)",
            "subtasks": ["Ordered list of atomic steps"],
            "dependencies": ["Blockers mentioned"],
            "estimatedMinutes": 15,
            "energyLevel": "low|medium|high",
            "contextTags": ["phone", "computer", "errand", "home", "work", "waiting"]
        }
        """

        return prompt
    }
}
