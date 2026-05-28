import Foundation

struct PromptIQClient {
    static let shared = PromptIQClient()

    let baseURL = URL(string: "https://h9-prompt-iq.netlify.app")!

    func listCustomPrompts() async throws -> [Prompt] {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/prompts"))
        req.httpMethod = "GET"
        try await authorize(&req)
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.verify(response)
        return try JSONDecoder().decode(PromptListResponse.self, from: data).prompts
    }

    func createPrompt(_ draft: NewPromptDraft) async throws {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/prompts"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(draft)
        try await authorize(&req)
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.verify(response, body: data)
    }

    func deletePrompt(named name: String) async throws {
        let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? name
        var req = URLRequest(url: baseURL.appendingPathComponent("api/prompts/\(encoded)"))
        req.httpMethod = "DELETE"
        try await authorize(&req)
        let (data, response) = try await URLSession.shared.data(for: req)
        try Self.verify(response, body: data)
    }

    private func authorize(_ req: inout URLRequest) async throws {
        let key = try await KeyProvider.shared.key()
        req.setValue(key, forHTTPHeaderField: "X-PromptIQ-Key")
    }

    private static func verify(_ response: URLResponse, body: Data = Data()) throws {
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: body))?["error"]
            throw APIError.status(http.statusCode, message: message)
        }
    }

    enum APIError: Error, LocalizedError {
        case badResponse
        case status(Int, message: String?)

        var errorDescription: String? {
            switch self {
            case .badResponse: return "Unexpected response"
            case .status(let code, let message):
                return "HTTP \(code)" + (message.map { ": \($0)" } ?? "")
            }
        }
    }
}
