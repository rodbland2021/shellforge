import Foundation

struct Theme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let foreground: String
    let background: String
    let cursor: String
    let selectionBackground: String
    let ansiColors: [String]  // 16 ANSI colours (0-15)

    static let solarizedDark = Theme(
        id: "solarized-dark", name: "Solarized Dark",
        foreground: "#839496", background: "#002B36",
        cursor: "#93A1A1", selectionBackground: "#073642",
        ansiColors: ["#073642","#DC322F","#859900","#B58900",
                     "#268BD2","#D33682","#2AA198","#EEE8D5",
                     "#002B36","#CB4B16","#586E75","#657B83",
                     "#839496","#6C71C4","#93A1A1","#FDF6E3"]
    )

    static let dracula = Theme(
        id: "dracula", name: "Dracula",
        foreground: "#F8F8F2", background: "#282A36",
        cursor: "#F8F8F2", selectionBackground: "#44475A",
        ansiColors: ["#21222C","#FF5555","#50FA7B","#F1FA8C",
                     "#BD93F9","#FF79C6","#8BE9FD","#F8F8F2",
                     "#6272A4","#FF6E6E","#69FF94","#FFFFA5",
                     "#D6ACFF","#FF92DF","#A4FFFF","#FFFFFF"]
    )

    static let nord = Theme(
        id: "nord", name: "Nord",
        foreground: "#D8DEE9", background: "#2E3440",
        cursor: "#D8DEE9", selectionBackground: "#434C5E",
        ansiColors: ["#3B4252","#BF616A","#A3BE8C","#EBCB8B",
                     "#81A1C1","#B48EAD","#88C0D0","#E5E9F0",
                     "#4C566A","#BF616A","#A3BE8C","#EBCB8B",
                     "#81A1C1","#B48EAD","#8FBCBB","#ECEFF4"]
    )

    static let monokai = Theme(
        id: "monokai", name: "Monokai",
        foreground: "#F8F8F2", background: "#272822",
        cursor: "#F8F8F0", selectionBackground: "#49483E",
        ansiColors: ["#272822","#F92672","#A6E22E","#F4BF75",
                     "#66D9EF","#AE81FF","#A1EFE4","#F8F8F2",
                     "#75715E","#F92672","#A6E22E","#F4BF75",
                     "#66D9EF","#AE81FF","#A1EFE4","#F9F8F5"]
    )

    static let allThemes: [Theme] = [.solarizedDark, .dracula, .nord, .monokai]

    static func theme(for id: String) -> Theme {
        allThemes.first { $0.id == id } ?? .solarizedDark
    }
}
