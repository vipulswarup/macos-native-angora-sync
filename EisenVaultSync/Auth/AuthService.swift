import Foundation
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authState: AuthState = .idle
    
    private let keychainManager = KeychainManager.shared
    private let networkManager = NetworkManager.shared
    private let accountManager = AccountManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        checkExistingAuth()
    }
    
    func login(email: String, password: String, serverURL: String = "https://jyothi.angoradev.in") async {
        print("🔐 Starting login process...")
        print("🔐 Email: \(email)")
        print("🔐 Server URL: \(serverURL)")
        
        await MainActor.run {
            self.authState = .loading
        }
        
        do {
            let loginRequest = LoginRequest(email: email, password: password)
            let requestData = try JSONEncoder().encode(loginRequest)
            
            guard let url = URL(string: "\(serverURL)/api/auth/login") else {
                print("❌ Invalid server URL: \(serverURL)")
                throw AuthError.networkError("Invalid server URL")
            }
            
            print("🔐 Making login request to: \(url.absoluteString)")
            
            let (response, cookies) = try await networkManager.makeRequestWithCookies(
                url: url,
                method: .POST,
                body: requestData,
                headers: [
                    "Content-Type": "application/json",
                    "Accept-Language": "en"
                ],
                responseType: LoginResponse.self
            )
            
            // Extract token from cookies
            guard let accessTokenCookie = cookies.first(where: { $0.name == "accessToken" }) else {
                throw AuthError.networkError("Access token not found in cookies")
            }
            let token = accessTokenCookie.value
            
            print("✅ Login successful!")
            print("✅ User: \(response.data.user.email)")
            print("✅ Token received: \(token.prefix(20))...")
            print("🏢 Customer: \(response.data.user.customerHostname)")
            
            await MainActor.run {
                self.currentUser = response.data.user
                self.isAuthenticated = true
                self.authState = .authenticated
                
                let accountKey = "\(serverURL)_\(email)"
                print("🔐 Storing credentials in keychain...")
                print("🔐 Account key: \(accountKey)")
                
                let passwordStored = self.keychainManager.store(account: accountKey, password: password)
                let tokenStored = self.keychainManager.storeToken(account: accountKey, token: token)
                
                // Store user data in keychain for persistence
                do {
                    let userData = try JSONEncoder().encode(response.data.user)
                    let userDataStored = self.keychainManager.storeUserData(account: accountKey, userData: userData)
                    print("🔐 User data stored: \(userDataStored)")
                } catch {
                    print("❌ Failed to encode user data: \(error)")
                }
                
                print("🔐 Password stored: \(passwordStored)")
                print("🔐 Token stored: \(tokenStored)")
                print("✅ Credentials saved to keychain successfully!")
            }
            
        } catch {
            print("❌ Login failed with error: \(error)")
            
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                
                if let authError = error as? AuthError {
                    print("❌ Auth error: \(authError.localizedDescription)")
                    self.authState = .error(authError.localizedDescription)
                } else if let networkError = error as? NetworkError {
                    print("❌ Network error: \(networkError.localizedDescription)")
                    self.authState = .error(networkError.localizedDescription)
                } else {
                    print("❌ Unknown error: \(error.localizedDescription)")
                    self.authState = .error("Login failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func logout() {
        if let activeAccount = accountManager.activeAccount {
            let accountKey = accountManager.getAccountKey(for: activeAccount)
            _ = keychainManager.delete(account: accountKey)
            _ = keychainManager.deleteToken(account: accountKey)
            _ = keychainManager.deleteUserData(account: accountKey)
        }
        
        currentUser = nil
        isAuthenticated = false
        authState = .idle
    }
    
    func verifyToken() async -> Bool {
        guard let activeAccount = accountManager.activeAccount else { 
            print("🔐 No active account found for token verification")
            return false 
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        print("🔐 Checking for token with account key: \(accountKey)")
        
        guard let token = keychainManager.retrieveToken(account: accountKey) else { 
            print("🔐 No token found in keychain for account: \(accountKey)")
            return false 
        }
        
        print("🔐 Token found in keychain, verifying with server...")
        
        do {
            guard let url = URL(string: "\(activeAccount.serverURL ?? "")/api/auth/token") else { return false }
            
            let response: TokenVerificationResponse = try await networkManager.makeRequest(
                url: url,
                method: .POST,
                headers: [
                    "Authorization": "Bearer \(token)",
                    "Accept-Language": "en"
                ],
                responseType: TokenVerificationResponse.self
            )
            
            // Check if the response indicates success
            if response.status == 200 {
                print("✅ Token verification successful")
                return true
            }
            
            print("❌ Token verification failed with status: \(response.status)")
            return false
        } catch {
            print("❌ Token verification error: \(error)")
            return false
        }
    }
    
    private func checkExistingAuth() {
        print("🔐 Checking for existing authentication...")
        
        // Check if there's an active account
        guard let activeAccount = accountManager.activeAccount else {
            print("❌ No active account found")
            isAuthenticated = false
            authState = .idle
            return
        }
        
        let accountKey = accountManager.getAccountKey(for: activeAccount)
        print("🔐 Checking active account: \(accountKey)")
        
        // Try to retrieve user data and token
        if let userData = keychainManager.retrieveUserData(account: accountKey),
           let _ = keychainManager.retrieveToken(account: accountKey) {
            
            do {
                let user = try JSONDecoder().decode(User.self, from: userData)
                print("🔐 Found stored user: \(user.email)")
                
                // Set current user and verify token
                currentUser = user
                
                Task {
                    let isValid = await verifyToken()
                    await MainActor.run {
                        if isValid {
                            print("✅ Found valid existing authentication")
                            self.isAuthenticated = true
                            self.authState = .authenticated
                        } else {
                            print("❌ Token verification failed")
                            self.isAuthenticated = false
                            self.authState = .idle
                        }
                    }
                }
                return
            } catch {
                print("❌ Failed to decode user data: \(error)")
            }
        }
        
        print("❌ No valid existing authentication found")
        isAuthenticated = false
        authState = .idle
    }
    
}
