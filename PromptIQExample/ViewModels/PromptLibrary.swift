import Foundation
import Observation

@MainActor
@Observable
final class PromptLibrary {
    var builtIns: [Prompt] = []
    var customs: [Prompt] = []
    var isLoading = false
    var lastError: String?

    init() {
        loadBuiltIns()
    }

    private func loadBuiltIns() {
        guard let url = Bundle.main.url(forResource: "prompts", withExtension: "json") else {
            lastError = "Bundled prompts.json missing"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            // Snapshot file is a top-level array.
            builtIns = try JSONDecoder().decode([Prompt].self, from: data)
        } catch {
            lastError = "Failed to parse built-ins: \(error.localizedDescription)"
        }
    }

    func refreshCustoms() async {
        isLoading = true
        defer { isLoading = false }
        do {
            customs = try await PromptIQClient.shared.listCustomPrompts()
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func create(_ draft: NewPromptDraft) async throws {
        try await PromptIQClient.shared.createPrompt(draft)
        await refreshCustoms()
    }
}
