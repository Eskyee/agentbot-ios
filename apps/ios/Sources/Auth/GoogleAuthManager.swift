import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class GoogleAuthManager: NSObject, ObservableObject {
    static let shared = GoogleAuthManager()
    
    @Published var isAuthenticating = false
    
    private var webSession: ASWebAuthenticationSession?
    
    private let googleClientId = "444006121351-hl2ln0igvd9lm6p8l0679sff2trfuijs.apps.googleusercontent.com"
    private let redirectUri = "https://agentbot.sh/api/auth/callback/google"
    
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
        
        let state = UUID().uuidString
        let scopes = ["email", "profile", "openid"].joined(separator: " ")
        
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: googleClientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "prompt", value: "select_account"),
            URLQueryItem(name: "access_type", value: "offline"),
        ]
        
        let authURL = components.url!
        
        let code: String = try await withCheckedThrowingContinuation { continuation in
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
                    let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)!
                    let authCode = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value ?? ""
                    if authCode.isEmpty {
                        continuation.resume(throwing: GoogleAuthError.noCode)
                        return
                    }
                    continuation.resume(returning: authCode)
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            self.webSession = session
            session.start()
        }
        
        // Exchange code for tokens and get user info via backend
        let userInfo = try await exchangeCodeForUserInfo(code)
        
        return AuthManager.AuthResponse(
            token: "google_\(userInfo.id)",
            user: AuthManager.User(
                id: "google_\(userInfo.id)",
                email: userInfo.email,
                name: userInfo.name,
                plan: "starter",
                features: ["dashboard", "marketplace", "chat"]
            )
        )
    }
    
    private func exchangeCodeForUserInfo(_ code: String) async throws -> GoogleUserInfo {
        // Try backend first, fall back to direct Google API
        do {
            struct BackendRequest: Codable {
                let code: String
                let redirectUri: String
            }
            let body = BackendRequest(code: code, redirectUri: redirectUri)
            let data = try await AuthManager.shared.authorizedRequest(
                path: "/api/auth/google/exchange",
                method: "POST",
                body: body
            )
            return try JSONDecoder().decode(GoogleUserInfo.self, from: data)
        } catch {
            // Fallback: decode id_token to get user info
            // The id_token is a JWT with user claims
            let urlComponents = URLComponents(string: "https://oauth2.googleapis.com/tokeninfo?id_token=\(code)")!
            let (tokenData, _) = try await URLSession.shared.data(from: urlComponents.url!)
            let tokenInfo = try JSONDecoder().decode(GoogleUserInfo.self, from: tokenData)
            return tokenInfo
        }
    }
    
    enum GoogleAuthError: LocalizedError {
        case noCallback
        case noCode
        
        var errorDescription: String? {
            switch self {
            case .noCallback: return "Google sign-in was cancelled."
            case .noCode: return "No authorization code received from Google."
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
