import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthService()
    
    var body: some View {
        if authService.isAuthenticated {
            MainView()
                .environmentObject(authService)
        } else {
            LoginView()
                .environmentObject(authService)
        }
    }
}

struct MainView: View {
    var body: some View {
        VStack {
            Text("Welcome to EisenVault Sync")
                .font(.title)
                .padding()
            
            Text("You are successfully logged in!")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(width: 400, height: 300)
    }
}

#Preview {
    ContentView()
}
