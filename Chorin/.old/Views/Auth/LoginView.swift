import SwiftUI
import Supabase

struct LoginView: View {
    @Environment(AppState.self) private var appState

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Branding
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 72))
                        .foregroundStyle(Theme.blue)
                    Text("Chorin'")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Track chores. Earn allowance.")
                        .font(.title3)
                        .foregroundStyle(Theme.textMuted)
                }

                // Form card
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(12)
                            .background(Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Theme.textPrimary)

                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding(12)
                            .background(Theme.inputBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(20)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Theme.border, lineWidth: 1)
                    )

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Theme.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isLoading { ProgressView().tint(.white) }
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        withAnimation { isSignUp.toggle() }
                        errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                            .font(.subheadline)
                            .foregroundStyle(Theme.activeBlue)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if isSignUp {
                try await supabase.auth.signUp(email: email, password: password)
            } else {
                try await supabase.auth.signIn(email: email, password: password)
            }
            await appState.bootstrap()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LoginView()
        .environment(AppState())
}
