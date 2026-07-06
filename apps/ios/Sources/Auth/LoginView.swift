import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var isSignup = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AgentbotBrand.accent)

                        Text("Agentbot")
                            .font(.largeTitle.bold())

                        Text("Your AI agent, always with you.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        if isSignup {
                            TextField("Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                                .autocorrectionDisabled()
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isSignup ? .newPassword : .password)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(isSignup ? "Create Account" : "Sign In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AgentbotBrand.accent)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    Button {
                        withAnimation { isSignup.toggle() }
                    } label: {
                        Text(isSignup
                            ? "Already have an account? Sign In"
                            : "Don't have an account? Sign Up")
                            .foregroundStyle(AgentbotBrand.accent)
                    }

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignup {
                try await auth.signup(
                    email: email,
                    password: password,
                    name: name.isEmpty ? nil : name
                )
            } else {
                try await auth.login(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
}
