import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authStore: AuthStore

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Text("Cookya")
                            .font(.largeTitle.bold())
                        Text(isSignUp ? "Create your account" : "Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 48)

                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                        if let errorMessage {
                            let isConfirmation = errorMessage.hasPrefix("Account created")
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(isConfirmation ? .green : .red)
                                .multilineTextAlignment(.center)
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.tint, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                            .opacity(canSubmit ? 1 : 0.5)
                        }
                        .disabled(!canSubmit || isLoading)
                    }

                    Button {
                        withAnimation { isSignUp.toggle() }
                        errorMessage = nil
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                            .font(.footnote)
                            .foregroundStyle(.tint)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            AppLogger.screen("SignIn")
        }
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password.count >= 6
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            if isSignUp {
                try await authStore.signUp(email: email, password: password)
            } else {
                try await authStore.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = errorMessage(from: error)
            AppLogger.action(
                isSignUp ? "auth_sign_up_failed" : "auth_sign_in_failed",
                screen: "SignIn",
                metadata: ["error": String(describing: error)]
            )
        }
    }

    private func errorMessage(from error: Error) -> String {
        if let authError = error as? AuthStore.AuthError, authError == .confirmationRequired {
            return "Account created! Check your email to confirm before signing in."
        }
        let description = error.localizedDescription.lowercased()
        if description.contains("invalid") || description.contains("credentials") {
            return "Incorrect email or password."
        }
        if description.contains("already") || description.contains("exists") {
            return "An account with this email already exists."
        }
        if description.contains("network") || description.contains("connection") {
            return "No internet connection. Please try again."
        }
        return "Something went wrong. Please try again."
    }
}
