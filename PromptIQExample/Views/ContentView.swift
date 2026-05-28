import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            PromptListView()
        }
    }
}

#Preview {
    ContentView()
        .environment(PromptLibrary())
}
