import SwiftUI

struct MultiAccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @State private var showingAccountSetup = false
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: SyncAccount?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Accounts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Add Account") {
                        showingAccountSetup = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if accountManager.accounts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No accounts configured")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first account to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(accountManager.accounts) { account in
                        AccountRowView(
                            account: account,
                            isActive: accountManager.activeAccount?.id == account.id,
                            onDelete: {
                                accountToDelete = account
                                showingDeleteAlert = true
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
        .sheet(isPresented: $showingAccountSetup) {
            AccountSetupView()
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

struct AccountRowView: View {
    let account: SyncAccount
    let isActive: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name ?? "Unnamed Account")
                        .font(.headline)
                    
                    if isActive {
                        Text("Active")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                
                Text(account.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(account.serverURL ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastSync = account.lastSync {
                    Text("Last sync: \(lastSync, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Delete") {
                onDelete()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MultiAccountView()
}
