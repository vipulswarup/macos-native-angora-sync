import Foundation
import Network

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = false
    @Published var connectionType: NWInterface.InterfaceType?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

extension NetworkManager {
    func makeRequest<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set custom headers (these will override defaults if provided)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Log the request details
        print("🌐 Making request to: \(url.absoluteString)")
        print("🌐 Method: \(method.rawValue)")
        print("🌐 Headers: \(headers)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("🌐 Request body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            // Log response details
            print("🌐 Response status: \(httpResponse.statusCode)")
            print("🌐 Response headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🌐 Response body: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to parse error response for more details
                if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                    print("❌ Server error: \(errorResponse.message)")
                    throw NetworkError.httpErrorWithMessage(httpResponse.statusCode, errorResponse.message)
                } else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
            }
            
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                print("❌ Decoding error: \(error)")
                throw NetworkError.decodingError(error)
            }
        } catch {
            if error is NetworkError {
                throw error
            } else {
                print("❌ Network error: \(error.localizedDescription)")
                throw NetworkError.networkError(error.localizedDescription)
            }
        }
    }
    
    func extractTokenFromCookies(url: URL) async throws -> String {
        // Create a URLSession with cookie storage
        let session = URLSession.shared
        
        // Make a simple request to get cookies
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              let headerFields = httpResponse.allHeaderFields as? [String: String] else {
            throw NetworkError.networkError("Could not extract cookies from response")
        }
        
        // Extract cookies from Set-Cookie headers
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        
        // Find the accessToken cookie
        if let accessTokenCookie = cookies.first(where: { $0.name == "accessToken" }) {
            return accessTokenCookie.value
        }
        
        throw NetworkError.networkError("Access token not found in cookies")
    }
    
    func makeRequestWithCookies<T: Codable>(
        url: URL,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = [:],
        responseType: T.Type
    ) async throws -> (response: T, cookies: [HTTPCookie]) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set default headers
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Set custom headers (these will override defaults if provided)
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Log the request details
        print("🌐 Making request to: \(url.absoluteString)")
        print("🌐 Method: \(method.rawValue)")
        print("🌐 Headers: \(headers)")
        if let body = body, let bodyString = String(data: body, encoding: .utf8) {
            print("🌐 Request body: \(bodyString)")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw NetworkError.invalidResponse
            }
            
            // Log response details
            print("🌐 Response status: \(httpResponse.statusCode)")
            print("🌐 Response headers: \(httpResponse.allHeaderFields)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🌐 Response body: \(responseString)")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to parse error response for more details
                if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
                    print("❌ Server error: \(errorResponse.message)")
                    throw NetworkError.httpErrorWithMessage(httpResponse.statusCode, errorResponse.message)
                } else {
                    print("❌ Server error: \(httpResponse.statusCode)")
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
            }
            
            // Extract cookies from response headers
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: httpResponse.allHeaderFields as! [String: String], for: url)
            
            do {
                let decoder = JSONDecoder()
                let decodedResponse = try decoder.decode(T.self, from: data)
                return (decodedResponse, cookies)
            } catch {
                print("❌ Decoding error: \(error)")
                throw NetworkError.decodingError(error)
            }
        } catch {
            if error is NetworkError {
                throw error
            } else {
                print("❌ Network error: \(error.localizedDescription)")
                throw NetworkError.networkError(error.localizedDescription)
            }
        }
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case httpErrorWithMessage(Int, String)
    case decodingError(Error)
    case networkError(String)
    case noConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .httpErrorWithMessage(let code, let message):
            return "HTTP error \(code): \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .noConnection:
            return "No internet connection"
        }
    }
}
