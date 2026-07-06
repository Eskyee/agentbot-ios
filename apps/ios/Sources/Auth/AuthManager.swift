import Foundation
import Security

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let baseURL = URL(string: "https://api.agentbot.sh")!
    private let keychainService = "sh.agentbot.app"

    struct User: Codable, Sendable {
        let id: String
        let email: String
        let name: String?
    }

    struct AuthResponse: Codable, Sendable {
        let token: String
        let user: User
    }

    struct LoginRequest: Codable, Sendable {
        let email: String
        let password: String
    }

    struct SignupRequest: Codable, Sendable {
        let email: String
        let password: String
        let name: String?
    }

    var token: String? {
        get { readFromKeychain(key: "authToken") }
        set {
            if let newValue = newValue {
                saveToKeychain(key: "authToken", value: newValue)
            } else {
                deleteFromKeychain(key: "authToken")
            }
        }
    }

    func login(email: String, password: String) async throws {
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await request(
            path: "/auth/login",
            method: "POST",
            body: body
        )

        self.token = response.token
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func signup(email: String, password: String, name: String?) async throws {
        let body = SignupRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await request(
            path: "/auth/signup",
            method: "POST",
            body: body
        )

        self.token = response.token
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func logout() {
        token = nil
        currentUser = nil
        isAuthenticated = false
    }

    func restoreSession() async {
        guard let token = token, !token.isEmpty else { return }

        do {
            let user: User = try await request(
                path: "/auth/me",
                method: "GET"
            )
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            logout()
        }
    }

    func authorizedRequest(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> Data {
        guard let token = token else {
            throw AuthError.notAuthenticated
        }

        var request = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw AuthError.serverError
        }

        return data
    }

    private func request<T: Decodable>(
        path: String,
        method: String,
        body: (any Encodable)? = nil
    ) async throws -> T {
        var request = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw AuthError.serverError
        }

        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func readFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return value
    }

    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]

        SecItemDelete(query as CFDictionary)
    }

    enum AuthError: LocalizedError {
        case notAuthenticated
        case serverError
        case invalidCredentials

        var errorDescription: String? {
            switch self {
            case .notAuthenticated:
                return "Please sign in to continue."
            case .serverError:
                return "Server error. Please try again."
            case .invalidCredentials:
                return "Invalid email or password."
            }
        }
    }
}
