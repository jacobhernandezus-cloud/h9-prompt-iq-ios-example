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

        // Netlify Blobs `list()` is eventually consistent (~30s lag for new
        // writes to appear in `/api/prompts`). We do NOT want the create UX
        // to depend on that lag — boss demos shouldn't include "wait 30s
        // and pull-to-refresh again." Prepend the new prompt locally so the
        // UI updates instantly, then reconcile from the server once Blobs
        // has caught up.
        let now = ISO8601DateFormatter().string(from: Date())
        let optimistic = Prompt(
            name: draft.name,
            category: draft.category,
            purpose: draft.purpose,
            purposeBody: nil,
            verbatim: draft.verbatim,
            parameterized: nil,
            tags: draft.tags,
            status: draft.status,
            model: nil,
            score: nil,
            author: nil,
            isCustom: true,
            createdAt: now
        )
        customs.removeAll { $0.name == optimistic.name }
        customs.insert(optimistic, at: 0)

        // Background reconciliation. If the server reflects the new prompt
        // by the time we refetch, the optimistic entry is replaced by the
        // canonical one. If the server gave it different fields (e.g. a
        // canonical createdAt), we converge on the server's truth.
        Task {
            try? await Task.sleep(for: .seconds(45))
            await refreshCustoms()
        }
    }

    /// Delete a custom prompt. Server-side delete is strongly consistent for
    /// GET-by-name but list() is eventually consistent (same lag as create) —
    /// so we also remove locally for an instant UI update.
    /// Only callable on custom prompts; the UI gates this.
    func delete(name: String) async throws {
        try await PromptIQClient.shared.deletePrompt(named: name)
        customs.removeAll { $0.name == name }
        // Background reconcile, in case anything diverged.
        Task {
            try? await Task.sleep(for: .seconds(45))
            await refreshCustoms()
        }
    }
}
