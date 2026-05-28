import SwiftUI

struct PromptListView: View {
    @Environment(PromptLibrary.self) private var library
    @State private var showingNewPrompt = false

    var body: some View {
        List {
            if !library.customs.isEmpty {
                Section("Custom") {
                    ForEach(library.customs) { prompt in
                        NavigationLink(value: prompt) { row(prompt) }
                    }
                }
            }
            Section("Built-in (\(library.builtIns.count))") {
                ForEach(library.builtIns) { prompt in
                    NavigationLink(value: prompt) { row(prompt) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("PromptIQ")
        .navigationDestination(for: Prompt.self) { PromptDetailView(prompt: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewPrompt = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New prompt")
            }
        }
        .refreshable { await library.refreshCustoms() }
        .sheet(isPresented: $showingNewPrompt) {
            NewPromptView()
        }
        .overlay {
            if library.isLoading && library.customs.isEmpty {
                ProgressView("Loading customs…")
            }
        }
        .alert("Error", isPresented: .init(
            get: { library.lastError != nil },
            set: { if !$0 { library.lastError = nil } }
        ), presenting: library.lastError) { _ in
            Button("OK") { library.lastError = nil }
        } message: { Text($0) }
    }

    private func row(_ prompt: Prompt) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(prompt.name)
                .font(.headline)
            if let purpose = prompt.purpose {
                Text(purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 6) {
                Text(prompt.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                if let status = prompt.status {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
