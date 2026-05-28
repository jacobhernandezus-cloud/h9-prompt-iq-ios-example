import SwiftUI

struct NewPromptView: View {
    @Environment(PromptLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: PromptCategory = .devCode
    @State private var purpose = ""
    @State private var verbatim = ""
    @State private var tagsText = ""
    @State private var submitting = false
    @State private var errorMessage: String?

    private var canSubmit: Bool {
        !name.isEmpty && !purpose.isEmpty && !verbatim.isEmpty && !submitting
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("slug-like-this", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Category", selection: $category) {
                        ForEach(PromptCategory.allCases) { cat in
                            Text(cat.display).tag(cat)
                        }
                    }
                } header: { brandSectionHeader("IDENTITY") }

                Section {
                    TextField("One-line purpose", text: $purpose, axis: .vertical)
                        .lineLimit(2...4)
                } header: { brandSectionHeader("PURPOSE") }

                Section {
                    TextEditor(text: $verbatim)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 160)
                } header: { brandSectionHeader("VERBATIM PROMPT") }

                Section {
                    TextField("equity, brief, dedup", text: $tagsText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: { brandSectionHeader("TAGS · COMMA-SEPARATED") }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.cream)
            .navigationTitle("NEW PROMPT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.orange)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await submit() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canSubmit ? Brand.orange : Brand.navy.opacity(0.4))
                    .disabled(!canSubmit)
                }
            }
            .overlay {
                if submitting {
                    ProgressView()
                        .controlSize(.large)
                        .tint(Brand.orange)
                }
            }
        }
    }

    private func brandSectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(Brand.orange).frame(width: 3, height: 12)
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(2)
                .foregroundStyle(Brand.navy)
        }
        .textCase(nil)
    }

    private func submit() async {
        submitting = true
        defer { submitting = false }
        let tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let draft = NewPromptDraft(
            name: name,
            category: category.rawValue,
            purpose: purpose,
            verbatim: verbatim,
            tags: tags.isEmpty ? nil : tags,
            status: "experimental"
        )
        do {
            try await library.create(draft)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
