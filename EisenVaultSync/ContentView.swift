import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    @StateObject private var accountManager = AccountManager.shared
    
    var body: some View {
        MainView()
            .environmentObject(authService)
            .environmentObject(accountManager)
    }
}

struct MainView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var accountManager: AccountManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            FolderBrowserView()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Folders")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .frame(width: 800, height: 600)
    }
}

struct DashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var accountManager: AccountManager
    @State private var showingAccountSetup = false
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: SyncAccount?
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to EisenVault Sync")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("\(accountManager.accounts.count) account(s) configured")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Add Account") {
                    showingAccountSetup = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            VStack(spacing: 16) {
                Text("Multi-Account Sync Active")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if accountManager.accounts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No accounts configured")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Add your first account to start syncing")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Account") {
                            showingAccountSetup = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(accountManager.accounts) { account in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name ?? "Unnamed Account")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(account.serverURL ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    if let lastSync = account.lastSync {
                                        Text("Last sync: \(lastSync, style: .relative)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Never synced")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button("Delete") {
                                        accountToDelete = account
                                        showingDeleteAlert = true
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingAccountSetup) {
            AccountSetupView()
                .environmentObject(authService)
        }
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let account = accountToDelete {
                    _ = accountManager.removeAccount(account)
                }
            }
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var accountManager: AccountManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Configured Accounts:")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(accountManager.accounts.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Information")
                        .font(.headline)
                    
                    Text("EisenVault Sync")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Version 0.0.1")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Multi-account document synchronization")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
