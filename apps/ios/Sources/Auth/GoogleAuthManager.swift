import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class GoogleAuthManager: NSObject, ObservableObject {
    static let shared = GoogleAuthManager()
    
    @Published var isAuthenticating = false
    
    private var webSession: ASWebAuthenticationSession?
    private var authContinuation: CheckedContinuation<AuthManager.AuthResponse, Error>?
    
    private let backendBaseURL = "https://agentbot-backend.fly.dev"
    
    struct GoogleTokenResponse: Codable {
        let access_token: String
        let token_type: String
        let expires_in: Int
        let refresh_token: String?
        let scope: String
        let id_token: String?
    }
    
    struct GoogleUserInfo: Codable {
        let id: String
        let email: String
        let verified_email: Bool
        let name: String
        let given_name: String?
        let family_name: String?
        let picture: String?
        let locale: String?
    }
    
    func signIn() async throws -> AuthManager.AuthResponse {
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        // Open the backend OAuth start endpoint
        // Backend redirects to Google, then back to agentbot://auth?token=xxx
        let authURL = URL(string: "\(backendBaseURL)/api/auth/google/start")!
        
        let response: AuthManager.AuthResponse = try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
            
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "agentbot") { callbackURL, error in
                Task { @MainActor in
                    if let error = error {
                        self.authContinuation?.resume(throwing: error)
                        self.authContinuation = nil
                        return
                    }
                    
                    guard let callbackURL = callbackURL else {
                        self.authContinuation?.resume(throwing: GoogleAuthError.noCallback)
                        self.authContinuation = nil
                        return
                    }
                    
                    let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)!
                    let token = components.queryItems?.first(where: { $0.name == "token" })?.value
                    let email = components.queryItems?.first(where: { $0.name == "email" })?.value
                    let name = components.queryItems?.first(where: { $0.name == "name" })?.value
                    let authError = components.queryItems?.first(where: { $0.name == "error" })?.value
                    
                    if let authError {
                        self.authContinuation?.resume(throwing: GoogleAuthError.authFailed(authError))
                        self.authContinuation = nil
                        return
                    }
                    
                    guard let token, let email else {
                        self.authContinuation?.resume(throwing: GoogleAuthError.noToken)
                        self.authContinuation = nil
                        return
                    }
                    
                    let authResponse = AuthManager.AuthResponse(
                        token: token,
                        user: AuthManager.User(
                            id: "google-\(email)",
                            email: email,
                            name: name,
                            plan: "starter",
                            features: ["dashboard", "marketplace", "chat"]
                        )
                    )
                    
                    self.authContinuation?.resume(returning: authResponse)
                    self.authContinuation = nil
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            self.webSession = session
            session.start()
        }
        
        return response
    }
    
    enum GoogleAuthError: LocalizedError {
        case noCallback
        case noToken
        case authFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .noCallback: return "Google sign-in was cancelled."
            case .noToken: return "No token received from Google."
            case .authFailed(let msg): return "Google auth failed: \(msg)"
            }
        }
    }
}

extension GoogleAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? UIWindow()
    }
}
