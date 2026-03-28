import Foundation
import Security

struct KeychainAccessTokenStore {
    func readAccessToken() throws -> String? {
        let query = readQuery()
        var result: CFTypeRef?

        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainAccessTokenStoreError.unexpectedData
            }

            return String(data: data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainAccessTokenStoreError.osStatus(status)
        }
    }

    func saveAccessToken(_ token: String) throws {
        let data = Data(token.utf8)
        let query = baseQuery()
        let attributesToUpdate = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        switch updateStatus {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            var addQuery = query
            addQuery[kSecValueData as String] = data

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainAccessTokenStoreError.osStatus(addStatus)
            }
        default:
            throw KeychainAccessTokenStoreError.osStatus(updateStatus)
        }
    }

    func deleteAccessToken() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainAccessTokenStoreError.osStatus(status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AppConfig.accessTokenService,
            kSecAttrAccount as String: AppConfig.accessTokenAccount,
        ]
    }

    private func readQuery() -> [String: Any] {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }
}

enum KeychainAccessTokenStoreError: LocalizedError {
    case unexpectedData
    case osStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .unexpectedData:
            return "The saved session token could not be read."
        case let .osStatus(status):
            return "Keychain operation failed with status \(status)."
        }
    }
}
