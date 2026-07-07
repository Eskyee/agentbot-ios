import Foundation

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()
    
    enum Environment: String, CaseIterable, Codable {
        case development, staging, production
        
        var baseURL: URL {
            switch self {
            case .development: return URL(string: "https://agentbot-backend.fly.dev")!
            case .staging: return URL(string: "https://agentbot-backend.fly.dev")!
            case .production: return URL(string: "https://agentbot-backend.fly.dev")!
            }
        }
    }
    
    @Published var currentEnvironment: Environment = .production
    
    private let session = URLSession.shared
    
    func request<T: Decodable>(_ endpoint: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> T {
        var urlRequest = URLRequest(url: currentEnvironment.baseURL.appendingPathComponent(endpoint))
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            urlRequest.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(httpResponse.statusCode, body)
        }
    }
    
    func upload<T: Decodable>(_ endpoint: String, data: Data, fileName: String, mimeType: String) async throws -> T {
        let boundary = UUID().uuidString
        var urlRequest = URLRequest(url: currentEnvironment.baseURL.appendingPathComponent(endpoint))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthManager.shared.token {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\(fileName)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        urlRequest.httpBody = body
        
        let (responseData, _) = try await session.data(for: urlRequest)
        return try JSONDecoder().decode(T.self, from: responseData)
    }
    
    enum APIError: LocalizedError {
        case invalidResponse
        case unauthorized
        case notFound
        case serverError(Int, String)
        
        var errorDescription: String? {
            switch self {
            case .invalidResponse: return "Invalid server response."
            case .unauthorized: return "Please sign in again."
            case .notFound: return "Resource not found."
            case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
            }
        }
    }
}