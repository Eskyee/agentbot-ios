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
        let email: String?
        let name: String?
        let plan: String?
        let features: [String]?
    }

    struct ValidateKeyResponse: Codable, Sendable {
        let valid: Bool
        let userId: String?
        let plan: String?
        let features: [String]?
        let error: String?
    }

    struct AuthResponse: Codable, Sendable {
        let token: String
        let user: User
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

    func loginWithAPIKey(_ apiKey: String) async throws {
        let response: ValidateKeyResponse = try await request(
            path: "/api/validate-key",
            method: "POST",
            body: nil,
            extraHeaders: ["Authorization": "Bearer \(apiKey)"]
        )

        guard response.valid, let userId = response.userId else {
            throw AuthError.invalidCredentials
        }

        self.token = apiKey
        self.currentUser = User(
            id: userId,
            email: nil,
            name: nil,
            plan: response.plan,
            features: response.features
        )
        self.isAuthenticated = true
    }

    func login(email: String, password: String) async throws {
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }
        let body = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await request(
            path: "/api/auth/login",
            method: "POST",
            body: body
        )

        self.token = response.token
        self.currentUser = response.user
        self.isAuthenticated = true
    }

    func signup(email: String, password: String, name: String?) async throws {
        struct SignupRequest: Codable {
            let email: String
            let password: String
            let name: String?
        }
        let body = SignupRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await request(
            path: "/api/auth/signup",
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
            let response: ValidateKeyResponse = try await request(
                path: "/api/validate-key",
                method: "POST",
                body: nil,
                extraHeaders: ["Authorization": "Bearer \(token)"]
            )

            guard response.valid, let userId = response.userId else {
                logout()
                return
            }

            self.currentUser = User(
                id: userId,
                email: nil,
                name: nil,
                plan: response.plan,
                features: response.features
            )
            self.isAuthenticated = true
        } catch {
            logout()
        }
    }

    func authorizedRequest(
        path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        extraHeaders: [String: String]? = nil
    ) async throws -> Data {
        guard let token = token else {
            throw AuthError.notAuthenticated
        }

        var urlRequest = URLRequest(
            url: baseURL.appendingPathComponent(path)
        )
        urlRequest.httpMethod = method
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let extraHeaders = extraHeaders {
            for (key, value) in extraHeaders {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        if let body = body {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

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
        body: (any Encodable)? = nil,
        extraHeaders: [String: String]? = nil
    ) async throws -> T {
        let data = try await authorizedRequest(
            path: path,
            method: method,
            body: body,
            extraHeaders: extraHeaders
        )
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
                return "Invalid API key."
            }
        }
    }
}
