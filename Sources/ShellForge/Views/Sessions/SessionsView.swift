import SwiftUI

struct SessionsView: View {
    @Bindable var sessionManager: SessionManager

    var body: some View {
        Group {
            if sessionManager.sessions.isEmpty {
                ContentUnavailableView(
                    "No Active Sessions",
                    systemImage: "terminal",
                    description: Text("Connect to a host to start a session")
                )
            } else {
                TabView(selection: Binding(
                    get: { sessionManager.activeSessionID },
                    set: { if let id = $0 { sessionManager.setActive(id) } }
                )) {
                    ForEach(sessionManager.sessions) { session in
                        SessionTabView(session: session, onClose: {
                            sessionManager.remove(id: session.id)
                        })
                        .tag(Optional(session.id))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
                .overlay(alignment: .top) {
                    if sessionManager.sessionCount > 1 {
                        SessionIndicator(
                            count: sessionManager.sessionCount,
                            activeIndex: sessionManager.sessions.firstIndex { $0.id == sessionManager.activeSessionID } ?? 0
                        )
                    }
                }
            }
        }
        .navigationTitle("Sessions")
    }
}

struct SessionTabView: View {
    let session: SessionManager.Session
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Session header bar
            HStack {
                Image(systemName: "terminal")
                Text(session.hostAlias)
                    .font(.caption).fontWeight(.medium)
                Spacer()
                Text(session.hostname)
                    .font(.caption2).foregroundStyle(.secondary)
                Button(role: .destructive) {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))

            // Terminal placeholder — will be replaced with actual TerminalContainerView
            Rectangle()
                .fill(Color(.systemBackground))
                .overlay(
                    Text("Terminal: \(session.hostAlias)")
                        .foregroundStyle(.secondary)
                )
        }
    }
}

struct SessionIndicator: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == activeIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }
}
