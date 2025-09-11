import SwiftUI

struct ErrorAlertView: View {
    let title: String
    let message: String
    let isPresented: Binding<Bool>
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Alert content
            VStack(spacing: 20) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                    .padding(.top, 20)
                
                // Title
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // OK button
                Button("OK") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 20)
            }
            .frame(width: 320, height: 200)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
    
    private func dismiss() {
        isPresented.wrappedValue = false
        onDismiss()
    }
}

struct ErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ErrorAlertView(
                    title: title,
                    message: message,
                    isPresented: $isPresented,
                    onDismiss: onDismiss
                )
            }
        }
    }
}

extension View {
    func errorAlert(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        self.modifier(ErrorAlertModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            onDismiss: onDismiss
        ))
    }
}
