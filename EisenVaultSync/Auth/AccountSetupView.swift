import SwiftUI

struct AccountSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authService = AuthService()
    
    @State private var accountName = ""
    @State private var serverURL = "https://binod.angorastage.in"
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Account")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Account Name", text: $accountName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Server URL", text: $serverURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocorrectionDisabled()
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            if isLoading {
                ProgressView("Setting up account...")
                    .frame(maxWidth: .infinity)
            } else {
                Button("Add Account") {
                    addAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(accountName.isEmpty || serverURL.isEmpty || email.isEmpty || password.isEmpty)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 300)
        .errorAlert(
            isPresented: $showError,
            title: "Login Failed",
            message: errorMessage
        )
    }
    
    private func addAccount() {
        guard !accountName.isEmpty,
              !serverURL.isEmpty,
              !email.isEmpty,
              !password.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            // First, try to authenticate with the server
            await authService.login(email: email, password: password, serverURL: serverURL)
            
            await MainActor.run {
                if authService.isAuthenticated {
                    // If authentication successful, add account to Core Data
                    let success = accountManager.addAccount(
                        name: accountName,
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
                        dismiss()
                    } else {
                        errorMessage = "Account already exists"
                        showError = true
                    }
                } else {
                    // Get specific error message from auth state and make it user-friendly
                    switch authService.authState {
                    case .error(let message):
                        if message.contains("Invalid Email or Password") {
                            errorMessage = "The email or password you entered is incorrect. Please check your credentials and try again."
                        } else if message.contains("HTTP error 400") {
                            errorMessage = "Invalid credentials. Please check your email and password."
                        } else if message.contains("Network error") {
                            errorMessage = "Unable to connect to the server. Please check your internet connection and try again."
                        } else {
                            errorMessage = message
                        }
                    default:
                        errorMessage = "Authentication failed. Please check your credentials and try again."
                    }
                    showError = true
                }
                isLoading = false
            }
        }
    }
}

#Preview {
    AccountSetupView()
}
