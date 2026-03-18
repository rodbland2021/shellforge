import Foundation
import Network
import NIOCore
import NIOPosix
import NIOSSH
import SwiftTerm

/// Manages an SSH connection lifecycle: connect -> authenticate -> open shell channel.
@Observable
final class SSHConnection {
    enum State: Equatable {
        case disconnected
        case connecting
        case authenticated
        case shellOpen
        case error(String)
    }

    private(set) var state: State = .disconnected
    private var group: MultiThreadedEventLoopGroup?
    private var parentChannel: Channel?
    private(set) var sessionChannel: Channel?

    /// Connect to a host, authenticate, and open a shell with PTY.
    func connect(
        host: String,
        port: Int = 22,
        username: String,
        authDelegate: NIOSSHClientUserAuthenticationDelegate,
        terminalView: TerminalView?,
        cols: Int = 80,
        rows: Int = 24
    ) async throws {
        state = .connecting
        lastConnectionParams = (host, port, username, authDelegate, terminalView, cols, rows)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group

        let bootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    let sshHandler = NIOSSHHandler(
                        role: .client(.init(
                            userAuthDelegate: authDelegate,
                            serverAuthDelegate: AcceptAllHostKeysDelegate()
                        )),
                        allocator: channel.allocator,
                        inboundChildChannelInitializer: nil
                    )
                    try channel.pipeline.syncOperations.addHandler(sshHandler)
                }
            }
            .channelOption(.socketOption(.so_reuseaddr), value: 1)
            .connectTimeout(.seconds(10))

        let channel = try await bootstrap.connect(host: host, port: port).get()
        self.parentChannel = channel
        state = .authenticated

        // Create session channel with shell
        let sshHandler = try await channel.pipeline.handler(type: NIOSSHHandler.self).get()
        let promise = channel.eventLoop.makePromise(of: Channel.self)

        let handler = SSHChannelHandler(terminalView: terminalView, cols: cols, rows: rows)

        sshHandler.createChannel(promise, channelType: .session) { childChannel, channelType in
            guard channelType == .session else {
                return childChannel.eventLoop.makeFailedFuture(SSHError.invalidChannelType)
            }
            return childChannel.eventLoop.makeCompletedFuture {
                try childChannel.pipeline.syncOperations.addHandler(handler)
            }
        }

        self.sessionChannel = try await promise.futureResult.get()
        state = .shellOpen
    }

    /// Send user keystrokes to the SSH channel
    func send(_ data: ArraySlice<UInt8>) {
        guard let channel = sessionChannel else { return }
        channel.eventLoop.execute {
            var buffer = channel.allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            let payload = SSHChannelData(type: .channel, data: .byteBuffer(buffer))
            channel.writeAndFlush(payload, promise: nil)
        }
    }

    /// Send a string to the SSH channel (convenience)
    func send(_ string: String) {
        send(ArraySlice(string.utf8))
    }

    /// Notify server of terminal resize
    func resize(cols: Int, rows: Int) {
        guard cols > 0, rows > 0, let channel = sessionChannel else { return }
        channel.eventLoop.execute {
            let event = SSHChannelRequestEvent.WindowChangeRequest(
                terminalCharacterWidth: cols,
                terminalRowHeight: rows,
                terminalPixelWidth: 0,
                terminalPixelHeight: 0
            )
            channel.triggerUserOutboundEvent(event, promise: nil)
        }
    }

    /// Execute a one-shot command and return its output (for tmux discovery, etc.)
    func exec(_ command: String) async throws -> String {
        guard let parentChannel else { throw SSHError.notConnected }

        let sshHandler = try await parentChannel.pipeline.handler(type: NIOSSHHandler.self).get()
        let promise = parentChannel.eventLoop.makePromise(of: Channel.self)
        let collector = OutputCollector()

        sshHandler.createChannel(promise, channelType: .session) { childChannel, _ in
            childChannel.eventLoop.makeCompletedFuture {
                try childChannel.pipeline.syncOperations.addHandler(collector)
            }
        }

        let channel = try await promise.futureResult.get()

        // Request exec (not shell)
        let exec = SSHChannelRequestEvent.ExecRequest(command: command, wantReply: true)
        channel.triggerUserOutboundEvent(exec, promise: nil)

        // Wait for channel to close (command finished)
        try await channel.closeFuture.get()
        return collector.output
    }

    // MARK: - Network Monitoring

    private var pathMonitor: NWPathMonitor?
    private var lastConnectionParams: (host: String, port: Int, username: String, authDelegate: NIOSSHClientUserAuthenticationDelegate, terminalView: TerminalView?, cols: Int, rows: Int)?

    /// Start monitoring network changes for auto-reconnect
    func startNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self, path.status == .satisfied else { return }
            if case .disconnected = self.state, self.lastConnectionParams != nil {
                Task { try? await self.reconnect() }
            }
        }
        pathMonitor?.start(queue: DispatchQueue(label: "shellforge.network-monitor"))
    }

    /// Reconnect using last connection parameters
    private func reconnect() async throws {
        guard let params = lastConnectionParams else { return }
        try await connect(
            host: params.host, port: params.port,
            username: params.username, authDelegate: params.authDelegate,
            terminalView: params.terminalView, cols: params.cols, rows: params.rows
        )
    }

    /// Stop network monitoring
    func stopNetworkMonitoring() {
        pathMonitor?.cancel()
        pathMonitor = nil
    }

    /// Disconnect and clean up
    func disconnect() {
        stopNetworkMonitoring()
        sessionChannel?.close(promise: nil)
        parentChannel?.close(promise: nil)
        try? group?.syncShutdownGracefully()
        group = nil
        sessionChannel = nil
        parentChannel = nil
        lastConnectionParams = nil
        state = .disconnected
    }
}

enum SSHError: Error, LocalizedError {
    case invalidChannelType
    case notConnected
    case authFailed
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidChannelType: return "Invalid SSH channel type"
        case .notConnected: return "Not connected to server"
        case .authFailed: return "Authentication failed"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        }
    }
}
