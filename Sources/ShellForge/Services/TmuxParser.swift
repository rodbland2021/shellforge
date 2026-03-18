import Foundation

struct TmuxParser {
    struct TmuxSession: Identifiable {
        let id: String
        let name: String
        let windowCount: Int
        let isAttached: Bool

        init(name: String, windowCount: Int, isAttached: Bool) {
            self.id = name
            self.name = name
            self.windowCount = windowCount
            self.isAttached = isAttached
        }
    }

    struct TmuxWindow: Identifiable {
        let id: String
        let index: Int
        let name: String
        let isActive: Bool

        init(index: Int, name: String, isActive: Bool) {
            self.id = "\(index)-\(name)"
            self.index = index
            self.name = name
            self.isActive = isActive
        }
    }

    struct TmuxPane: Identifiable {
        let id: String
        let width: Int
        let height: Int
        let isActive: Bool
    }

    /// Parse output of `tmux list-sessions`
    /// Example: "cc: 3 windows (created Mon Mar 18 10:00:00 2026) (attached)"
    static func parseSessions(_ output: String) -> [TmuxSession] {
        output.split(separator: "\n").compactMap { line in
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard !str.isEmpty else { return nil }
            guard let colonIdx = str.firstIndex(of: ":") else { return nil }
            let name = String(str[str.startIndex..<colonIdx])

            // Extract window count: look for "N windows" or "1 window"
            var windowCount = 1
            if let match = str.range(of: #"(\d+) windows?"#, options: .regularExpression) {
                let numStr = str[match].split(separator: " ").first ?? "1"
                windowCount = Int(numStr) ?? 1
            }

            let isAttached = str.contains("(attached)")
            return TmuxSession(name: name, windowCount: windowCount, isAttached: isAttached)
        }
    }

    /// Parse output of `tmux list-windows -t <session> -F '#{window_index}: #{window_name} #{?window_active,(active),}'`
    static func parseWindows(_ output: String) -> [TmuxWindow] {
        output.split(separator: "\n").compactMap { line in
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard !str.isEmpty else { return nil }

            let parts = str.split(separator: ":", maxSplits: 1)
            guard parts.count >= 2, let index = Int(parts[0].trimmingCharacters(in: .whitespaces)) else { return nil }

            let rest = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let isActive = rest.contains("(active)")
            let name = rest.replacingOccurrences(of: "(active)", with: "").trimmingCharacters(in: .whitespaces)

            return TmuxWindow(index: index, name: name, isActive: isActive)
        }
    }

    /// Parse output of `tmux list-panes -t <session>`
    /// Example: "%0: [80x24] [history 1500/50000 bytes] (active)"
    static func parsePanes(_ output: String) -> [TmuxPane] {
        output.split(separator: "\n").compactMap { line in
            let str = String(line).trimmingCharacters(in: .whitespaces)
            guard !str.isEmpty else { return nil }

            // Extract pane ID (%N)
            guard let percentIdx = str.firstIndex(of: "%") else { return nil }
            let afterPercent = str[percentIdx...]
            let idEnd = afterPercent.firstIndex(of: ":") ?? afterPercent.endIndex
            let id = String(afterPercent[percentIdx..<idEnd])

            // Extract dimensions [WxH]
            var width = 80
            var height = 24
            if let bracketStart = str.firstIndex(of: "["),
               let bracketEnd = str[bracketStart...].firstIndex(of: "]") {
                let dims = String(str[str.index(after: bracketStart)..<bracketEnd])
                let parts = dims.split(separator: "x")
                if parts.count == 2 {
                    width = Int(parts[0]) ?? 80
                    height = Int(parts[1]) ?? 24
                }
            }

            let isActive = str.contains("(active)")
            return TmuxPane(id: id, width: width, height: height, isActive: isActive)
        }
    }

    /// Parse output of `tmux capture-pane -t <pane> -p` (just returns the raw text)
    static func parseCapturePane(_ output: String) -> String {
        output
    }

    // MARK: - tmux Commands

    static let listSessionsCmd = "tmux list-sessions 2>/dev/null"

    static func listWindowsCmd(session: String) -> String {
        "tmux list-windows -t '\(session)' -F '#{window_index}: #{window_name} #{?window_active,(active),}'"
    }

    static func listPanesCmd(session: String) -> String {
        "tmux list-panes -t '\(session)'"
    }

    static func capturePaneCmd(paneID: String) -> String {
        "tmux capture-pane -t '\(paneID)' -p"
    }

    static func attachCmd(session: String) -> String {
        "tmux attach-session -t '\(session)'"
    }

    static func newSessionCmd(name: String) -> String {
        "tmux new-session -d -s '\(name)'"
    }

    static func killSessionCmd(session: String) -> String {
        "tmux kill-session -t '\(session)'"
    }

    static func renameSessionCmd(session: String, newName: String) -> String {
        "tmux rename-session -t '\(session)' '\(newName)'"
    }
}
