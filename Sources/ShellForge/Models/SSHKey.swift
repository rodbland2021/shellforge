import Foundation
import SwiftData

@Model
final class SSHKey {
    var name: String
    var keyType: KeyType
    var publicKeyData: Data?
    var keychainID: String
    var createdAt: Date

    enum KeyType: String, Codable {
        case ed25519
        case ecdsa256
        case rsa2048
        case rsa4096
    }

    init(name: String, keyType: KeyType, keychainID: String, publicKeyData: Data? = nil) {
        self.name = name
        self.keyType = keyType
        self.keychainID = keychainID
        self.publicKeyData = publicKeyData
        self.createdAt = Date()
    }
}
