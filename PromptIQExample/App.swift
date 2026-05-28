import SwiftUI

@main
struct PromptIQExampleApp: App {
    @State private var library = PromptLibrary()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(library)
                .task { await library.refreshCustoms() }
        }
    }
}
