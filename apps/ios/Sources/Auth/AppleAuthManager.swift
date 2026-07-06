import Foundation
import AuthenticationServices

@MainActor
final class AppleAuthManager: NSObject, ObservableObject {
    static let shared = AppleAuthManager()
    
    func handleAuthorization(_ authorization: ASAuthorization) async throws -> AuthManager.AuthResponse {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AppleAuthError.invalidCredential
        }
        
        let idToken = String(data: credential.identityToken ?? Data(), encoding: .utf8) ?? ""
        let userIdentifier = credential.user
        let fullName = credential.fullName
        let name = [fullName?.givenName, fullName?.familyName].compactMap { $0 }.joined(separator: " ")
        
        struct AppleLoginRequest: Codable {
            let token: String
            let userId: String
            let name: String?
        }
        
        let body = AppleLoginRequest(token: idToken, userId: userIdentifier, name: name.isEmpty ? nil : name)
        let data = try await AuthManager.shared.authorizedRequest(
            path: "/auth/apple",
            method: "POST",
            body: body
        )
        return try JSONDecoder().decode(AuthManager.AuthResponse.self, from: data)
    }
    
    enum AppleAuthError: LocalizedError {
        case invalidCredential
        var errorDescription: String? { "Invalid Apple credential." }
    }
}

extension AppleAuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task {
            do {
                let response = try await handleAuthorization(authorization)
                await MainActor.run {
                    AuthManager.shared.token = response.token
                    AuthManager.shared.currentUser = response.user
                    AuthManager.shared.isAuthenticated = true
                }
            } catch {
                print("[Agentbot] Apple auth failed: \(error)")
            }
        }
    }
}