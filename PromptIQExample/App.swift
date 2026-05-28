import SwiftUI

@main
struct PromptIQExampleApp: App {
    @State private var library = PromptLibrary()

    init() {
        Brand.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(library)
                .tint(Brand.orange)
                .task { await library.refreshCustoms() }
        }
    }
}
