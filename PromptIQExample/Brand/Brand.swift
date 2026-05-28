import SwiftUI
import UIKit

/// H9 Partners brand tokens — colors, fonts, and global appearance.
/// Source: H9_Partners_Branding_Guidelines.pptx (slides 11–14).
enum Brand {
    // ── Colors ────────────────────────────────────────────────
    static let orange = Color(red: 1.00, green: 0.549, blue: 0.00)    // #FF8C00 — primary accent
    static let navy = Color(red: 0.078, green: 0.137, blue: 0.220)    // #142338 — primary dark
    static let cream = Color(red: 0.980, green: 0.973, blue: 0.957)   // #FAF8F4 — light surface
    static let lightGray = Color(red: 0.941, green: 0.941, blue: 0.941) // #F0F0F0
    static let textBlack = Color(red: 0.118, green: 0.118, blue: 0.118) // #1E1E1E

    // UIKit twins (for UINavigationBarAppearance, etc.)
    static let uiOrange    = UIColor(red: 1.00, green: 0.549, blue: 0.00, alpha: 1)
    static let uiNavy      = UIColor(red: 0.078, green: 0.137, blue: 0.220, alpha: 1)
    static let uiCream     = UIColor(red: 0.980, green: 0.973, blue: 0.957, alpha: 1)
    static let uiTextBlack = UIColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1)

    // ── Typography ────────────────────────────────────────────
    // Posterama2001-Thin is bundled via UIAppFonts (declared in project.yml).
    // If the font fails to load for any reason, callers fall back to system.
    enum Display {
        static func font(size: CGFloat) -> Font {
            Font.custom("Posterama2001-Thin", size: size)
        }
    }

    // ── Global appearance ────────────────────────────────────
    /// Configure UIKit appearance proxies. Call once at launch.
    static func configureAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = uiNavy
        nav.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "Posterama2001-Thin", size: 18)
                ?? .systemFont(ofSize: 18, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont(name: "Posterama2001-Thin", size: 34)
                ?? .systemFont(ofSize: 34, weight: .bold)
        ]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = uiOrange  // back-buttons + bar items
    }
}
