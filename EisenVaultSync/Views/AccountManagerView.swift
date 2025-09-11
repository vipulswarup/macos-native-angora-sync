import SwiftUI

struct AccountManagerView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authService = AuthService()
    @State private var showingAccountSetup = false
    @State private var showingMultiAccountView = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Account Management")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let activeAccount = accountManager.activeAccount {
                        Text("Active: \(activeAccount.name ?? "Unnamed")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Manage Accounts") {
                    showingMultiAccountView = true
                }
                .buttonStyle(.bordered)
            }
            
            // Account Status
            if let activeAccount = accountManager.activeAccount {
                AccountStatusCard(account: activeAccount)
            } else {
                NoAccountCard()
            }
            
            // Quick Actions
            VStack(spacing: 12) {
                Button("Add New Account") {
                    showingAccountSetup = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                
                if accountManager.activeAccount != nil {
                    Button("Logout") {
                        authService.logout()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
        .sheet(isPresented: $showingAccountSetup) {
            AccountSetupView()
        }
        .sheet(isPresented: $showingMultiAccountView) {
            MultiAccountView()
        }
    }
}

struct AccountStatusCard: View {
    let account: SyncAccount
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name ?? "Unnamed Account")
                        .font(.headline)
                    
                    Text(account.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Server")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(account.serverURL ?? "")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last Sync")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let lastSync = account.lastSync {
                        Text(lastSync, style: .relative)
                            .font(.subheadline)
                    } else {
                        Text("Never")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct NoAccountCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Active Account")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add an account to start syncing your data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

#Preview {
    AccountManagerView()
}
