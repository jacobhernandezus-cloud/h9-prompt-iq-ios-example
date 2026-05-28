import SwiftUI

struct PromptListView: View {
    @Environment(PromptLibrary.self) private var library
    @State private var showingNewPrompt = false

    var body: some View {
        List {
            Section {
                brandHeader
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if !library.customs.isEmpty {
                Section {
                    ForEach(library.customs) { prompt in
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
                    sectionHeader("CUSTOM", count: library.customs.count)
                }
            }

            Section {
                ForEach(library.builtIns) { prompt in
                    NavigationLink(value: prompt) { row(prompt) }
                }
            } header: {
                sectionHeader("BUILT-IN", count: library.builtIns.count)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Brand.cream)
        .navigationTitle("PROMPT IQ")
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
            VStack(alignment: .leading, spacing: 6) {
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
                    .font(Brand.Display.font(size: 40))
                    .foregroundStyle(.white)
                    .tracking(3)
                    .padding(.top, 8)
                Text("AVIATION INFRASTRUCTURE REIMAGINED")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
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
