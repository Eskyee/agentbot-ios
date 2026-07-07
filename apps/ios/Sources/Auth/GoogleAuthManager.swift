import Foundation
import AuthenticationServices
import UIKit

@MainActor
final class GoogleAuthManager: NSObject, ObservableObject {
    static let shared = GoogleAuthManager()
    
    @Published var isAuthenticating = false
    
    private var webSession: ASWebAuthenticationSession?
    
    // Your Google OAuth Client ID
    private let googleClientId = "444006121351-hl2ln0igvd9lm6p8l0679sff2trfuijs.apps.googleusercontent.com"
    
    // Redirect to your website which will handle the callback
    private let redirectUri = "https://agentbot.sh/api/auth/google/callback"
    
    func signIn() async throws -> AuthManager.AuthResponse {
        isAuthenticating = true
        defer { isAuthenticating = false }
        
        let state = UUID().uuidString
        let scopes = ["email", "profile"].joined(separator: " ")
        
        // Build Google OAuth URL
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
                    
                    // Extract code from callback URL
                    let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)!
                    let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value ?? ""
                    
                    if code.isEmpty {
                        continuation.resume(throwing: GoogleAuthError.noCode)
                        return
                    }
                    
                    // Mock login with Google code (backend exchange not ready yet)
                    let mockResponse = AuthManager.AuthResponse(
                        token: "google_\(code.prefix(20))",
                        user: AuthManager.User(
                            id: "google_user",
                            email: "user@gmail.com",
                            name: "Google User",
                            plan: "starter",
                            features: ["dashboard", "marketplace", "chat"]
                        )
                    )
                    
                    continuation.resume(returning: mockResponse)
                }
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = self
            self.webSession = session
            session.start()
        }
    }
    
    enum GoogleAuthError: LocalizedError {
        case noCallback
        case noCode
        
        var errorDescription: String? {
            switch self {
            case .noCallback:
                return "Google sign-in was cancelled."
            case .noCode:
                return "No authorization code received from Google."
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
