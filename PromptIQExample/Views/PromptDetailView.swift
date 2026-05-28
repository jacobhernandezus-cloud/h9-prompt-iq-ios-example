import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt

    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if let purpose = prompt.purpose {
                    section("PURPOSE", text: purpose)
                }
                if let body = prompt.purposeBody, body != prompt.purpose {
                    section("DETAIL", text: body)
                }
                if let verbatim = prompt.verbatim {
                    section("VERBATIM", text: verbatim, mono: true, highlight: true)
                }
                if let parameterized = prompt.parameterized {
                    section("PARAMETERIZED", text: parameterized, mono: true)
                }
                if let tags = prompt.tags, !tags.isEmpty {
                    tagCloud(tags)
                }
            }
            .padding()
        }
        .background(Brand.cream)
        .navigationTitle(prompt.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let verbatim = prompt.verbatim {
                    ShareLink(item: verbatim) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Brand.orange)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = prompt.verbatim ?? prompt.purpose ?? ""
                    copied = true
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(Brand.orange)
                }
                .accessibilityLabel("Copy prompt")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(prompt.category)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Brand.orange, in: Capsule())
                if prompt.isCustom == true {
                    Text("CUSTOM")
                        .font(.caption2)
                        .tracking(1.5)
                        .foregroundStyle(Brand.navy)
                }
                Spacer()
                if let score = prompt.score {
                    Text("\(score)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Brand.navy)
                }
            }
            if let model = prompt.model {
                Text("Model · \(model)")
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(.secondary)
            }
            if let author = prompt.author {
                Text("Author · \(author)")
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func section(_ title: String, text: String, mono: Bool = false, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Brand.orange)
                    .frame(width: 3, height: 14)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(2)
                    .foregroundStyle(Brand.navy)
            }
            Text(text)
                .font(mono ? .system(.body, design: .monospaced) : .body)
                .foregroundStyle(Brand.textBlack)
                .textSelection(.enabled)
                .padding(highlight ? 12 : 0)
                .background(highlight ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    highlight ?
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Brand.orange.opacity(0.25), lineWidth: 1)
                    : nil
                )
        }
    }

    private func tagCloud(_ tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Brand.orange)
                    .frame(width: 3, height: 14)
                Text("TAGS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(2)
                    .foregroundStyle(Brand.navy)
            }
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundStyle(Brand.navy)
                        .background(Brand.lightGray, in: Capsule())
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
