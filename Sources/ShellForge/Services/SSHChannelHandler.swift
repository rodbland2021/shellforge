import Foundation
import NIOCore
import NIOSSH
import SwiftTerm

/// Bridges an SSH channel to a SwiftTerm TerminalView.
/// Receives SSH data -> feeds to terminal. Terminal keystrokes -> sent via SSHConnection.send().
final class SSHChannelHandler: ChannelDuplexHandler {
    typealias InboundIn = SSHChannelData
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = ByteBuffer
    typealias OutboundOut = SSHChannelData

    private weak var terminalView: TerminalView?
    private let initialCols: Int
    private let initialRows: Int

    init(terminalView: TerminalView?, cols: Int = 80, rows: Int = 24) {
        self.terminalView = terminalView
        self.initialCols = cols
        self.initialRows = rows
    }

    func handlerAdded(context: ChannelHandlerContext) {
        // Request PTY
        let pty = SSHChannelRequestEvent.PseudoTerminalRequest(
            wantReply: true,
            term: "xterm-256color",
            terminalCharacterWidth: initialCols,
            terminalRowHeight: initialRows,
            terminalPixelWidth: 0,
            terminalPixelHeight: 0,
            terminalModes: .init([:])
        )
        context.triggerUserOutboundEvent(pty, promise: nil)

        // Request shell
        let shell = SSHChannelRequestEvent.ShellRequest(wantReply: true)
        context.triggerUserOutboundEvent(shell, promise: nil)
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let payload = unwrapInboundIn(data)
        guard case .byteBuffer(var buffer) = payload.data,
              let bytes = buffer.readBytes(length: buffer.readableBytes),
              !bytes.isEmpty else { return }

        // Feed to terminal on main thread in 1024-byte chunks
        let slice = ArraySlice(bytes)
        DispatchQueue.main.async { [weak self] in
            self?.terminalView?.feed(byteArray: slice)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("[ShellForge SSH] Channel error: \(error)")
        context.close(promise: nil)
    }
}

/// Collects output from a one-shot exec channel (used for tmux discovery, etc.)
final class OutputCollector: ChannelInboundHandler {
    typealias InboundIn = SSHChannelData
    var output = ""

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let payload = unwrapInboundIn(data)
        guard case .byteBuffer(var buffer) = payload.data,
              let str = buffer.readString(length: buffer.readableBytes) else { return }
        output += str
    }
}
