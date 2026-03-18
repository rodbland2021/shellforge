import SwiftUI

struct TmuxPanePreview: View {
    let content: String
    let width: Int
    let height: Int
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pane content (last few lines)
            Text(lastLines(6))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(isActive ? .primary : .secondary)
                .lineLimit(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isActive ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isActive ? 2 : 1)
        )
    }

    private func lastLines(_ count: Int) -> String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
        let last = lines.suffix(count)
        return last.joined(separator: "\n")
    }
}
