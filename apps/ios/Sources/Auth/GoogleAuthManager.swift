import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class GoogleAuthManager: NSObject, ObservableObject {
    static let shared = GoogleAuthManager()
    
    @Published var isAuthenticating = false
    
    private var webSession: ASWebAuthenticationSession?
    private let googleClientId = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    private let redirectUri = "https://api.agentbot.sh/auth/google/callback"
    
    func signIn() async throws -> AuthManager.AuthResponse {
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        let state = UUID().uuidString
        let scopes = ["email", "profile"].joined(separator: " ")
        
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: googleClientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "prompt", value: "select_account"),
        ]
        
        let authURL = components.url!
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "agentbot") { callbackURL, error in
                Task { @MainActor in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let callbackURL = callbackURL else {
                        continuation.resume(throwing: GoogleAuthError.noCallback)
                        return
                    }
                    do {
                        let response = try await self.exchangeCode(callbackURL)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            self.webSession = session
            session.start()
        }
    }
    
    private func exchangeCode(_ callbackURL: URL) async throws -> AuthManager.AuthResponse {
        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)!
        let code = components.queryItems?.first(where: { $0.name == "code" })?.value ?? ""
        
        struct GoogleExchangeRequest: Codable {
            let code: String
            let redirectUri: String
        }
        
        let body = GoogleExchangeRequest(code: code, redirectUri: redirectUri)
        let data = try await AuthManager.shared.authorizedRequest(
            path: "/auth/google/exchange",
            method: "POST",
            body: body
        )
        return try JSONDecoder().decode(AuthManager.AuthResponse.self, from: data)
    }
    
    enum GoogleAuthError: LocalizedError {
        case noCallback
        var errorDescription: String? { "Google sign-in was cancelled." }
    }
}

extension GoogleAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first ?? UIWindow()
    }
}