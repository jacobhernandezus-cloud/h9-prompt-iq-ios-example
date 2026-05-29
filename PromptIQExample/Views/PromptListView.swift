import SwiftUI

struct PromptListView: View {
    @Environment(PromptLibrary.self) private var library
    @State private var showingNewPrompt = false
    @State private var query = ""

    private var filteredCustoms: [Prompt] {
        Self.filter(library.customs, by: query)
    }

    private var filteredBuiltIns: [Prompt] {
        Self.filter(library.builtIns, by: query)
    }

    private static func filter(_ prompts: [Prompt], by query: String) -> [Prompt] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return prompts }
        return prompts.filter { p in
            p.name.lowercased().contains(q)
                || (p.purpose?.lowercased().contains(q) ?? false)
                || (p.tags?.contains(where: { $0.lowercased().contains(q) }) ?? false)
                || p.category.lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            // Header only when not searching — gives the search results full vertical real estate.
            if query.isEmpty {
                Section {
                    brandHeader
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }

            if !filteredCustoms.isEmpty {
                Section {
                    ForEach(filteredCustoms) { prompt in
                        NavigationLink(value: prompt) { row(prompt) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { try? await library.delete(name: prompt.name) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    sectionHeader("CUSTOM", count: filteredCustoms.count)
                }
            }

            if !filteredBuiltIns.isEmpty {
                Section {
                    ForEach(filteredBuiltIns) { prompt in
                        NavigationLink(value: prompt) { row(prompt) }
                    }
                } header: {
                    sectionHeader("BUILT-IN", count: filteredBuiltIns.count)
                }
            }

            if !query.isEmpty && filteredCustoms.isEmpty && filteredBuiltIns.isEmpty {
                Section {
                    Text("No prompts match \"\(query)\".")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Brand.cream)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search prompts")
        // Header card is the title — no need to repeat "PROMPT IQ" in the nav bar.
        // Empty string keeps the nav bar styled (navy + Posterama appearance proxy
        // is set globally in Brand.configureAppearance) but suppresses the duplicate.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Prompt.self) { PromptDetailView(prompt: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewPrompt = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Brand.orange)
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
                    .tint(Brand.orange)
            }
        }
        .alert("Error", isPresented: .init(
            get: { library.lastError != nil },
            set: { if !$0 { library.lastError = nil } }
        ), presenting: library.lastError) { _ in
            Button("OK") { library.lastError = nil }
        } message: { Text($0) }
    }

    // ── Brand header card ────────────────────────────────────
    private var brandHeader: some View {
        ZStack(alignment: .leading) {
            Brand.navy
            VStack(alignment: .leading, spacing: 4) {
                // H9 wordmark in a thin orange border — echoes the logo lockup
                Text("H9 PARTNERS")
                    .font(Brand.Display.font(size: 16))
                    .foregroundStyle(Brand.orange)
                    .tracking(4)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .strokeBorder(Brand.orange, lineWidth: 1.5)
                    )
                Text("PROMPT IQ")
                    .font(Brand.Display.font(size: 36))
                    .foregroundStyle(.white)
                    .tracking(3)
                    .padding(.top, 4)
                Text("AVIATION INFRASTRUCTURE REIMAGINED")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(maxWidth: .infinity)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Brand.orange)
                .frame(width: 3, height: 14)
            Text("\(title) · \(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(2)
                .foregroundStyle(Brand.navy)
        }
        .textCase(nil)
    }

    private func row(_ prompt: Prompt) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(prompt.name)
                .font(.headline)
                .foregroundStyle(Brand.textBlack)
            if let purpose = prompt.purpose {
                Text(purpose)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            HStack(spacing: 6) {
                Text(prompt.category)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Brand.orange, in: Capsule())
                if let status = prompt.status {
                    Text(status.uppercased())
                        .font(.caption2)
                        .tracking(1)
                        .foregroundStyle(Brand.navy.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 4)
    }
}
