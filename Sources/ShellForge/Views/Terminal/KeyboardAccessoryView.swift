import SwiftUI

struct KeyboardAccessoryView: View {
    let onKey: (String) -> Void

    @State private var ctrlActive = false

    private struct SpecialKey: Identifiable {
        let id: String
        let label: String
        let value: String
        let isModifier: Bool

        init(_ label: String, _ value: String, isModifier: Bool = false) {
            self.id = label
            self.label = label
            self.value = value
            self.isModifier = isModifier
        }
    }

    private let keys: [SpecialKey] = [
        SpecialKey("Esc", "\u{1B}"),
        SpecialKey("Ctrl", "", isModifier: true),
        SpecialKey("Tab", "\t"),
        SpecialKey("↑", "\u{1B}[A"),
        SpecialKey("↓", "\u{1B}[B"),
        SpecialKey("←", "\u{1B}[D"),
        SpecialKey("→", "\u{1B}[C"),
        SpecialKey("|", "|"),
        SpecialKey("~", "~"),
        SpecialKey("-", "-"),
        SpecialKey("/", "/"),
        SpecialKey("_", "_"),
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(keys) { key in
                    Button {
                        handleKeyPress(key)
                    } label: {
                        Text(key.label)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .frame(minWidth: 36, minHeight: 36)
                            .background(
                                key.isModifier && ctrlActive
                                    ? Color.accentColor.opacity(0.3)
                                    : Color(.secondarySystemBackground)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color(.systemBackground))
        .frame(height: 44)
    }

    private func handleKeyPress(_ key: SpecialKey) {
        HapticManager.impact(.light)

        if key.isModifier {
            ctrlActive.toggle()
            return
        }

        if ctrlActive {
            // Send Ctrl+key: for a-z, Ctrl+X = ASCII value of X - 64
            // e.g. Ctrl+C = 3, Ctrl+D = 4, Ctrl+Z = 26
            if key.value.count == 1,
               let char = key.value.uppercased().first,
               char.isLetter,
               let ascii = char.asciiValue {
                let ctrlCode = ascii - 64
                onKey(String(UnicodeScalar(ctrlCode)))
            } else {
                onKey(key.value)
            }
            ctrlActive = false
        } else {
            onKey(key.value)
        }
    }
}
