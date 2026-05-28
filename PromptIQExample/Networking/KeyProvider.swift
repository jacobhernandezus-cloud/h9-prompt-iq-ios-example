import Foundation

actor KeyProvider {
    static let shared = KeyProvider()

    private let keyURL = URL(string: "https://h9-prompt-iq.netlify.app/config.local.js")!
    private var cached: String?

    func key() async throws -> String {
        if let cached { return cached }
        let (data, response) = try await URLSession.shared.data(from: keyURL)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw KeyError.fetchFailed
        }
        guard let text = String(data: data, encoding: .utf8),
              let parsed = Self.parse(text) else {
            throw KeyError.parseFailed
        }
        cached = parsed
        return parsed
    }

    func invalidate() {
        cached = nil
    }

    private static func parse(_ text: String) -> String? {
        // Expected shape: `window.PROMPT_IQ_KEY = "..."`
        guard let range = text.range(of: #"PROMPT_IQ_KEY\s*=\s*"([^"]+)""#,
                                     options: .regularExpression) else { return nil }
        let matched = text[range]
        guard let quoted = matched.range(of: #""([^"]+)""#, options: .regularExpression) else { return nil }
        let withQuotes = matched[quoted]
        return String(withQuotes.dropFirst().dropLast())
    }

    enum KeyError: Error, LocalizedError {
        case fetchFailed
        case parseFailed

        var errorDescription: String? {
            switch self {
            case .fetchFailed: return "Could not download PromptIQ key file"
            case .parseFailed: return "Key file format unexpected"
            }
        }
    }
}
