import Foundation
import Security

struct KeychainService {
    private let serviceName = "com.rodbland.shellforge"

    func save(password: String, for id: String) throws {
        let data = Data(password.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: id,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Try to add
        var status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Update existing
            let searchQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: id
            ]
            let update: [String: Any] = [kSecValueData as String: data]
            status = SecItemUpdate(searchQuery as CFDictionary, update as CFDictionary)
        }

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    func retrievePassword(for id: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: id,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.itemNotFound
        }
        return password
    }

    func delete(id: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: id
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case itemNotFound
    case deleteFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status): return "Keychain save failed (OSStatus: \(status))"
        case .itemNotFound: return "Keychain item not found"
        case .deleteFailed(let status): return "Keychain delete failed (OSStatus: \(status))"
        }
    }
}
