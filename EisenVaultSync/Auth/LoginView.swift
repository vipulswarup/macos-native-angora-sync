import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = "pankaj.singh@eisenvault.com"
    @State private var password = "Admin@765"
    @State private var serverURL = "https://jyothi.angoradev.in"
    @State private var showPassword = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("EisenVault Sync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to sync your documents")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Server URL")
                        .font(.headline)
                    
                    TextField("https://jyothi.angoradev.in", text: $serverURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                    
                    TextField("user@example.com", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                    
                    HStack {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                        
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                Button(action: {
                    Task {
                        await authService.login(email: email, password: password, serverURL: serverURL)
                    }
                }) {
                    HStack {
                        if authService.authState == .loading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        Text("Sign In")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(authService.authState == .loading || email.isEmpty || password.isEmpty)
                
                if case .error(let message) = authService.authState {
                    Text(message)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(width: 500, height: 600)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
