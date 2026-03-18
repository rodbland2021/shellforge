import SwiftUI

struct AIPanelView: View {
    @Bindable var aiService: AIService
    @State private var userInput = ""
    @State private var response = ""
    @State private var suggestedCommand: String?
    @State private var isLoading = false
    let terminalContext: String
    let onCommand: (String) -> Void

    var body: some View {
        VStack(spacing: 12) {
            if !response.isEmpty {
                ScrollView {
                    Text(response)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxHeight: 200)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if let cmd = suggestedCommand {
                    Button {
                        onCommand(cmd)
                        suggestedCommand = nil
                        HapticManager.impact(.medium)
                    } label: {
                        Label("Run: \(cmd)", systemImage: "play.fill")
                            .lineLimit(1)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            HStack {
                TextField("Ask AI or type in English...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .onSubmit { sendQuery() }

                Button { sendQuery() } label: {
                    if isLoading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .disabled(userInput.isEmpty || isLoading || !aiService.hasAPIKey)
            }

            if !aiService.hasAPIKey {
                Text("Add an API key in Settings > AI to use the assistant")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding()
    }

    private func sendQuery() {
        guard !userInput.isEmpty else { return }
        isLoading = true
        suggestedCommand = nil
        let query = userInput
        userInput = ""

        Task {
            do {
                let systemPrompt = """
                You are a terminal assistant inside an SSH client on iOS. \
                The user is connected to a Linux server. \
                Recent terminal output for context:
                ```
                \(String(terminalContext.suffix(2000)))
                ```
                If the user asks for a command, respond with ONLY the command (no explanation, no markdown). \
                If the user asks to explain something, give a concise explanation (2-3 sentences max).
                """
                let result = try await aiService.ask(systemPrompt: systemPrompt, userMessage: query)

                let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.contains("\n"), looksLikeCommand(trimmed) {
                    suggestedCommand = trimmed
                    response = "Command: `\(trimmed)`"
                } else {
                    response = trimmed
                }
            } catch {
                response = "Error: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    private func looksLikeCommand(_ text: String) -> Bool {
        let prefixes = ["ls", "cd", "cat", "grep", "find", "du", "df", "ps", "kill",
                        "sudo", "apt", "systemctl", "docker", "git", "ssh", "curl",
                        "wget", "tar", "chmod", "chown", "mkdir", "rm", "cp", "mv",
                        "top", "htop", "tail", "head", "echo", "awk", "sed", "sort",
                        "tmux", "screen", "npm", "pip", "python", "node", "make"]
        return prefixes.contains { text.hasPrefix($0) }
    }
}
