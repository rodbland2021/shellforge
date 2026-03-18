import Foundation
import SwiftData

@Model
final class Host {
    var alias: String
    var hostname: String
    var port: Int
    var username: String
    var authMethod: AuthMethod
    var sshKeyID: String?
    var startupCommand: String?
    var lastConnected: Date?
    var sortOrder: Int
    var createdAt: Date

    enum AuthMethod: String, Codable {
        case password
        case publicKey
    }

    init(
        alias: String,
        hostname: String,
        port: Int = 22,
        username: String,
        authMethod: AuthMethod = .password,
        sshKeyID: String? = nil,
        startupCommand: String? = nil,
        sortOrder: Int = 0
    ) {
        self.alias = alias
        self.hostname = hostname
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.sshKeyID = sshKeyID
        self.startupCommand = startupCommand
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
