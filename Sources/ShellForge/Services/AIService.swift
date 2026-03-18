import Foundation

@Observable
final class AIService {
    enum Provider: String, Codable, CaseIterable, Identifiable {
        case anthropic = "Anthropic (Claude)"
        case openai = "OpenAI (GPT)"

        var id: String { rawValue }
    }

    var provider: Provider {
        get { Provider(rawValue: UserDefaults.standard.string(forKey: "aiProvider") ?? Provider.anthropic.rawValue) ?? .anthropic }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "aiProvider") }
    }

    var model: String {
        get { UserDefaults.standard.string(forKey: "aiModel") ?? defaultModel }
        set { UserDefaults.standard.set(newValue, forKey: "aiModel") }
    }

    var apiKey: String {
        get { (try? KeychainService().retrievePassword(for: "ai-api-key")) ?? "" }
        set { try? KeychainService().save(password: newValue, for: "ai-api-key") }
    }

    var hasAPIKey: Bool { !apiKey.isEmpty }

    private var defaultModel: String {
        switch provider {
        case .anthropic: return "claude-sonnet-4-6-20250514"
        case .openai: return "gpt-4o"
        }
    }

    /// Available models per provider
    var availableModels: [String] {
        switch provider {
        case .anthropic: return ["claude-sonnet-4-6-20250514", "claude-haiku-4-5-20251001"]
        case .openai: return ["gpt-4o", "gpt-4o-mini"]
        }
    }

    /// Send a message and return the response
    func ask(systemPrompt: String, userMessage: String) async throws -> String {
        guard hasAPIKey else { throw AIError.noAPIKey }

        let request = try buildRequest(systemPrompt: systemPrompt, userMessage: userMessage)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.requestFailed("No HTTP response")
        }
        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "unknown"
            throw AIError.requestFailed("HTTP \(httpResponse.statusCode): \(body)")
        }

        return try parseResponse(data)
    }

    private func buildRequest(systemPrompt: String, userMessage: String) throws -> URLRequest {
        switch provider {
        case .anthropic:
            return try buildAnthropicRequest(system: systemPrompt, user: userMessage)
        case .openai:
            return try buildOpenAIRequest(system: systemPrompt, user: userMessage)
        }
    }

    private func buildAnthropicRequest(system: String, user: String) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": system,
            "messages": [["role": "user", "content": user]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func buildOpenAIRequest(system: String, user: String) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.invalidResponse
        }
        switch provider {
        case .anthropic:
            if let content = json["content"] as? [[String: Any]],
               let text = content.first?["text"] as? String { return text }
        case .openai:
            if let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let text = message["content"] as? String { return text }
        }
        throw AIError.invalidResponse
    }
}

enum AIError: Error, LocalizedError {
    case noAPIKey
    case requestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key configured. Add one in Settings > AI."
        case .requestFailed(let msg): return "AI request failed: \(msg)"
        case .invalidResponse: return "Could not parse AI response"
        }
    }
}
