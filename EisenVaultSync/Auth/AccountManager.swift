import Foundation
import CoreData
import Combine

class AccountManager: ObservableObject {
    static let shared = AccountManager()
    
    @Published var accounts: [SyncAccount] = []
    @Published var activeAccount: SyncAccount?
    
    private let persistenceController = PersistenceController.shared
    private let keychainManager = KeychainManager.shared
    
    private init() {
        loadAccounts()
    }
    
    func loadAccounts() {
        let request: NSFetchRequest<SyncAccount> = SyncAccount.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SyncAccount.createdAt, ascending: false)]
        
        do {
            accounts = try persistenceController.container.viewContext.fetch(request)
            activeAccount = accounts.first { $0.isActive }
        } catch {
            print("Failed to load accounts: \(error)")
        }
    }
    
    func addAccount(name: String, serverURL: String, email: String) -> Bool {
        let context = persistenceController.container.viewContext
        
        // Check if account already exists
        let existingRequest: NSFetchRequest<SyncAccount> = SyncAccount.fetchRequest()
        existingRequest.predicate = NSPredicate(format: "serverURL == %@ AND email == %@", serverURL, email)
        
        do {
            let existingAccounts = try context.fetch(existingRequest)
            if !existingAccounts.isEmpty {
                return false // Account already exists
            }
        } catch {
            print("Error checking existing accounts: \(error)")
            return false
        }
        
        let newAccount = SyncAccount(context: context)
        newAccount.id = UUID()
        newAccount.name = name
        newAccount.serverURL = serverURL
        newAccount.email = email
        newAccount.isActive = accounts.isEmpty // First account becomes active for backward compatibility
        newAccount.createdAt = Date()
        
        do {
            try context.save()
            loadAccounts()
            return true
        } catch {
            print("Failed to save account: \(error)")
            return false
        }
    }
    
    func switchToAccount(_ account: SyncAccount) {
        let context = persistenceController.container.viewContext
        
        // Deactivate all accounts
        accounts.forEach { $0.isActive = false }
        
        // Activate selected account
        account.isActive = true
        
        do {
            try context.save()
            activeAccount = account
        } catch {
            print("Failed to switch account: \(error)")
        }
    }
    
    func removeAccount(_ account: SyncAccount) -> Bool {
        let context = persistenceController.container.viewContext
        
        // Delete credentials from keychain
        let accountKey = "\(account.serverURL ?? "")_\(account.email ?? "")"
        _ = keychainManager.delete(account: accountKey)
        _ = keychainManager.deleteToken(account: accountKey)
        _ = keychainManager.deleteUserData(account: accountKey)
        
        // If removing active account, activate another one
        if account.isActive && accounts.count > 1 {
            let otherAccounts = accounts.filter { $0 != account }
            if let nextAccount = otherAccounts.first {
                nextAccount.isActive = true
            }
        }
        
        context.delete(account)
        
        do {
            try context.save()
            loadAccounts()
            return true
        } catch {
            print("Failed to remove account: \(error)")
            return false
        }
    }
    
    func getAccountKey(for account: SyncAccount) -> String {
        return "\(account.serverURL ?? "")_\(account.email ?? "")"
    }
    
    func updateLastSync(for account: SyncAccount) {
        let context = persistenceController.container.viewContext
        account.lastSync = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to update last sync: \(error)")
        }
    }
    
    func getAllAccounts() -> [SyncAccount] {
        return accounts
    }
    
    func getActiveAccount() -> SyncAccount? {
        return activeAccount
    }
}
