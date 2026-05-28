import Foundation

struct Prompt: Codable, Identifiable, Hashable {
    let name: String
    let category: String
    var purpose: String?
    var purposeBody: String?
    var verbatim: String?
    var parameterized: String?
    var tags: [String]?
    var status: String?
    var model: String?
    var score: Int?
    var author: String?
    var isCustom: Bool?
    var createdAt: String?

    var id: String { name }
}

struct PromptListResponse: Codable {
    let prompts: [Prompt]
}

struct NewPromptDraft: Codable {
    let name: String
    let category: String
    let purpose: String
    let verbatim: String
    var tags: [String]?
    var status: String?
}
