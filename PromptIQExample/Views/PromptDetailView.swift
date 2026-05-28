import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt

    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let purpose = prompt.purpose {
                    section("Purpose", text: purpose)
                }
                if let body = prompt.purposeBody, body != prompt.purpose {
                    section("Detail", text: body)
                }
                if let verbatim = prompt.verbatim {
                    section("Verbatim", text: verbatim, mono: true)
                }
                if let parameterized = prompt.parameterized {
                    section("Parameterized", text: parameterized, mono: true)
                }
                if let tags = prompt.tags, !tags.isEmpty {
                    tagCloud(tags)
                }
            }
            .padding()
        }
        .navigationTitle(prompt.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let verbatim = prompt.verbatim {
                    ShareLink(item: verbatim) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = prompt.verbatim ?? prompt.purpose ?? ""
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                }
                .accessibilityLabel("Copy prompt")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(prompt.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                if prompt.isCustom == true {
                    Text("custom")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let score = prompt.score {
                    Text("\(score)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if let model = prompt.model {
                Text("Model: \(model)").font(.caption).foregroundStyle(.secondary)
            }
            if let author = prompt.author {
                Text("Author: \(author)").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func section(_ title: String, text: String, mono: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text)
                .font(mono ? .system(.body, design: .monospaced) : .body)
                .textSelection(.enabled)
        }
    }

    private func tagCloud(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags").font(.headline)
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.15), in: Capsule())
                }
            }
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var (rowWidth, rowHeight, totalHeight): (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                rowWidth = 0; rowHeight = 0
            }
            rowWidth += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: maxWidth, height: totalHeight + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
