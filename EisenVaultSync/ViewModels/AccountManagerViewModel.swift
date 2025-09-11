import Foundation
import Combine

class AccountManagerViewModel: ObservableObject {
    @Published var accounts: [SyncAccount] = []
    @Published var activeAccount: SyncAccount?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let accountManager = AccountManager.shared
    private let authService = AuthService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadAccounts()
    }
    
    private func setupBindings() {
        accountManager.$accounts
            .receive(on: DispatchQueue.main)
            .assign(to: \.accounts, on: self)
            .store(in: &cancellables)
        
        accountManager.$activeAccount
            .receive(on: DispatchQueue.main)
            .assign(to: \.activeAccount, on: self)
            .store(in: &cancellables)
    }
    
    func loadAccounts() {
        accountManager.loadAccounts()
    }
    
    func addAccount(name: String, serverURL: String, email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Authenticate with the server first
            await authService.login(email: email, password: password, serverURL: serverURL)
            
            await MainActor.run {
                if authService.isAuthenticated {
                    // Add account to Core Data
                    let success = accountManager.addAccount(
                        name: name,
                        serverURL: serverURL,
                        email: email
                    )
                    
                    if success {
                        // Switch to the new account
                        if let newAccount = accountManager.accounts.first(where: { 
                            $0.serverURL == serverURL && $0.email == email 
                        }) {
                            accountManager.switchToAccount(newAccount)
                        }
                    } else {
                        errorMessage = "Account already exists"
                    }
                } else {
                    errorMessage = "Authentication failed. Please check your credentials."
                }
                isLoading = false
            }
            
            return authService.isAuthenticated && errorMessage == nil
        }
    }
    
    func switchToAccount(_ account: SyncAccount) {
        accountManager.switchToAccount(account)
        
        // Update auth service with new account context
        if let userData = getStoredUserData(for: account) {
            do {
                let user = try JSONDecoder().decode(User.self, from: userData)
                authService.currentUser = user
                authService.isAuthenticated = true
                authService.authState = .authenticated
            } catch {
                print("Failed to decode user data: \(error)")
                errorMessage = "Failed to load account data"
            }
        }
    }
    
    func removeAccount(_ account: SyncAccount) -> Bool {
        let success = accountManager.removeAccount(account)
        
        // If we removed the active account, logout
        if success && account.isActive {
            authService.logout()
        }
        
        return success
    }
    
    func logout() {
        authService.logout()
    }
    
    func getStoredUserData(for account: SyncAccount) -> Data? {
        let accountKey = accountManager.getAccountKey(for: account)
        return KeychainManager.shared.retrieveUserData(account: accountKey)
    }
    
    func getStoredToken(for account: SyncAccount) -> String? {
        let accountKey = accountManager.getAccountKey(for: account)
        return KeychainManager.shared.retrieveToken(account: accountKey)
    }
    
    func validateAccount(_ account: SyncAccount) async -> Bool {
        guard let token = getStoredToken(for: account) else {
            return false
        }
        
        do {
            guard let url = URL(string: "\(account.serverURL ?? "")/api/auth/token") else {
                return false
            }
            
            let response: TokenVerificationResponse = try await NetworkManager.shared.makeRequest(
                url: url,
                method: .POST,
                headers: [
                    "Authorization": "Bearer \(token)",
                    "Accept-Language": "en"
                ],
                responseType: TokenVerificationResponse.self
            )
            
            return response.status == 200
        } catch {
            return false
        }
    }
    
    func updateLastSync(for account: SyncAccount) {
        accountManager.updateLastSync(for: account)
    }
}
