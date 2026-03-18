import Foundation
import SwiftTerm

@Observable
final class SessionManager {
    struct Session: Identifiable {
        let id: UUID
        let hostAlias: String
        let hostname: String
        let connection: SSHConnection
        weak var terminalView: TerminalView?
        let connectedAt: Date

        init(hostAlias: String, hostname: String, connection: SSHConnection, terminalView: TerminalView? = nil) {
            self.id = UUID()
            self.hostAlias = hostAlias
            self.hostname = hostname
            self.connection = connection
            self.terminalView = terminalView
            self.connectedAt = Date()
        }
    }

    private(set) var sessions: [Session] = []
    var activeSessionID: UUID?

    var activeSession: Session? {
        sessions.first { $0.id == activeSessionID }
    }

    var sessionCount: Int { sessions.count }

    func add(hostAlias: String, hostname: String, connection: SSHConnection, terminalView: TerminalView? = nil) {
        let session = Session(hostAlias: hostAlias, hostname: hostname, connection: connection, terminalView: terminalView)
        sessions.append(session)
        activeSessionID = session.id
    }

    func remove(id: UUID) {
        sessions.first { $0.id == id }?.connection.disconnect()
        sessions.removeAll { $0.id == id }
        if activeSessionID == id {
            activeSessionID = sessions.last?.id
        }
    }

    func setActive(_ id: UUID) {
        if sessions.contains(where: { $0.id == id }) {
            activeSessionID = id
        }
    }

    func disconnectAll() {
        sessions.forEach { $0.connection.disconnect() }
        sessions.removeAll()
        activeSessionID = nil
    }
}
