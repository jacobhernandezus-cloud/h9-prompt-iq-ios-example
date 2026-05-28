import Foundation

enum PromptCategory: String, CaseIterable, Identifiable, Codable {
    case tradeResearch = "trade-research"
    case ipoResearch = "ipo-research"
    case aviationUnderwriting = "aviation-underwriting"
    case aviationResearch = "aviation-research"
    case devCode = "dev-code"
    case brandDesign = "brand-design"
    case docGeneration = "doc-generation"
    case portfolioMgmt = "portfolio-mgmt"
    case strategicPlanning = "strategic-planning"
    case metaClaude = "meta-claude"

    var id: String { rawValue }

    var display: String {
        switch self {
        case .tradeResearch: return "Trade Research"
        case .ipoResearch: return "IPO Research"
        case .aviationUnderwriting: return "Aviation Underwriting"
        case .aviationResearch: return "Aviation Research"
        case .devCode: return "Dev / Code"
        case .brandDesign: return "Brand & Design"
        case .docGeneration: return "Doc Generation"
        case .portfolioMgmt: return "Portfolio Mgmt"
        case .strategicPlanning: return "Strategic Planning"
        case .metaClaude: return "Meta Claude"
        }
    }
}
