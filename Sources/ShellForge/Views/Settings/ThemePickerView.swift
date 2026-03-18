import SwiftUI

struct ThemePickerView: View {
    @Bindable private var settings = AppSettings.shared

    var body: some View {
        List(Theme.allThemes) { theme in
            Button {
                settings.themeID = theme.id
            } label: {
                HStack {
                    // Theme preview swatch
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: theme.background))
                        .frame(width: 60, height: 40)
                        .overlay(
                            Text(">_")
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color(hex: theme.foreground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.name).font(.headline)
                        HStack(spacing: 2) {
                            ForEach(0..<8, id: \.self) { i in
                                Circle()
                                    .fill(Color(hex: theme.ansiColors[i]))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                    .padding(.leading, 8)

                    Spacer()

                    if settings.themeID == theme.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.accentColor)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Theme")
    }
}

// Hex colour extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
