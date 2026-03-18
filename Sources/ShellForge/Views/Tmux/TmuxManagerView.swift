import SwiftUI

struct TmuxManagerView: View {
    let connection: SSHConnection
    let onAttach: (String) -> Void

    @State private var sessions: [TmuxParser.TmuxSession] = []
    @State private var isLoading = true
    @State private var showNewSession = false
    @State private var newSessionName = ""

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Discovering tmux sessions...")
                } else if sessions.isEmpty {
                    ContentUnavailableView(
                        "No tmux Sessions",
                        systemImage: "rectangle.split.3x1",
                        description: Text("Create a session to get started")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: [.init(.adaptive(minimum: 160))], spacing: 12) {
                            ForEach(sessions) { session in
                                TmuxSessionCard(session: session, onTap: {
                                    onAttach(session.name)
                                }, onKill: {
                                    killSession(session.name)
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("tmux Sessions")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewSession = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button { Task { await refresh() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .alert("New Session", isPresented: $showNewSession) {
                TextField("Session name", text: $newSessionName)
                Button("Create") { createSession() }
                Button("Cancel", role: .cancel) { newSessionName = "" }
            }
            .task { await refresh() }
        }
    }

    private func refresh() async {
        isLoading = true
        do {
            let output = try await connection.exec(TmuxParser.listSessionsCmd)
            sessions = TmuxParser.parseSessions(output)
        } catch {
            sessions = []
        }
        isLoading = false
    }

    private func createSession() {
        let name = newSessionName.isEmpty ? "session-\(sessions.count + 1)" : newSessionName
        newSessionName = ""
        Task {
            _ = try? await connection.exec(TmuxParser.newSessionCmd(name: name))
            HapticManager.notification(.success)
            await refresh()
        }
    }

    private func killSession(_ name: String) {
        Task {
            _ = try? await connection.exec(TmuxParser.killSessionCmd(session: name))
            HapticManager.notification(.warning)
            await refresh()
        }
    }
}

struct TmuxSessionCard: View {
    let session: TmuxParser.TmuxSession
    let onTap: () -> Void
    let onKill: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "terminal")
                        .foregroundStyle(.accentColor)
                    Text(session.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    if session.isAttached {
                        Image(systemName: "link")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Text("\(session.windowCount) window\(session.windowCount == 1 ? "" : "s")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onTap()
            } label: {
                Label("Attach", systemImage: "arrow.right.circle")
            }
            Button(role: .destructive) {
                onKill()
            } label: {
                Label("Kill Session", systemImage: "trash")
            }
        }
    }
}
