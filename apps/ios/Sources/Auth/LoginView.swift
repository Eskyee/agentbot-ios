import SwiftUI
import AuthenticationServices
import AVFoundation

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var apiKey = ""
    @State private var name = ""
    @State private var isSignup = false
    @State private var loginMode: LoginMode = .apiKey
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showQRScanner = false
    
    enum LoginMode {
        case apiKey, email
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 60)

                    VStack(spacing: 8) {
                        Text("🦞")
                            .font(.system(size: 64))

                        Text("Agentbot")
                            .font(.largeTitle.bold())

                        Text("Your AI agent, always with you.")
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Login Mode", selection: $loginMode) {
                        Text("API Key").tag(LoginMode.apiKey)
                        Text("Email").tag(LoginMode.email)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 32)

                    VStack(spacing: 16) {
                        if loginMode == .apiKey {
                            TextField("API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        } else {
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
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else if loginMode == .apiKey {
                                Text("Connect with API Key")
                            } else {
                                Text(isSignup ? "Create Account" : "Sign In")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AgentbotBrand.accent)
                    .disabled(isLoading || (loginMode == .apiKey ? apiKey.isEmpty : (email.isEmpty || password.isEmpty)))

                    Button {
                        withAnimation { isSignup.toggle() }
                    } label: {
                        Text(isSignup
                            ? "Already have an account? Sign In"
                            : "Don't have an account? Sign Up")
                            .foregroundStyle(AgentbotBrand.accent)
                    }
                    
                    Divider()
                        .padding(.horizontal, 32)
                    
                    HStack(spacing: 16) {
                        Button {
                            Task { await googleSignIn() }
                        } label: {
                            HStack {
                                Image(systemName: "g.circle.fill")
                                Text("Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading)
                        
                        Button {
                            Task { await appleSignIn() }
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 32)
                    
                    Button {
                        showQRScanner = true
                    } label: {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan QR Code to Login")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AgentbotBrand.accent.opacity(0.1))
                        .foregroundStyle(AgentbotBrand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .padding(.horizontal, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .sheet(isPresented: $showQRScanner) {
                LoginQRScannerSheet()
            }
        }
    }

    private func submit() async {
        isLoading = true
        errorMessage = nil

        do {
            if loginMode == .apiKey {
                try await auth.loginWithAPIKey(apiKey)
            } else {
                if isSignup {
                    try await auth.signup(
                        email: email,
                        password: password,
                        name: name.isEmpty ? nil : name
                    )
                } else {
                    try await auth.login(email: email, password: password)
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
    
    private func googleSignIn() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await GoogleAuthManager.shared.signIn()
            auth.token = response.token
            auth.currentUser = response.user
            auth.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func appleSignIn() async {
        isLoading = true
        errorMessage = nil
        let controller = ASAuthorizationController(authorizationRequests: [
            ASAuthorizationAppleIDProvider().createRequest()
        ])
        controller.delegate = AppleAuthManager.shared
        controller.performRequests()
        isLoading = false
    }
}

struct LoginQRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthManager.shared
    @State private var cameraPermission = false
    @State private var scanned = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if cameraPermission {
                    LoginQRScannerRepresentable { code in
                        guard !scanned else { return }
                        scanned = true
                        handleCode(code)
                    }
                    .ignoresSafeArea()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Camera access required to scan QR codes.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Grant Access") {
                            Task {
                                let granted = await AVCaptureDevice.requestAccess(for: .video)
                                await MainActor.run { cameraPermission = granted }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                await MainActor.run { cameraPermission = status == .authorized }
                if status == .notDetermined {
                    let granted = await AVCaptureDevice.requestAccess(for: .video)
                    await MainActor.run { cameraPermission = granted }
                }
            }
        }
    }
    
    private func handleCode(_ code: String) {
        if let url = URL(string: code),
           url.scheme == "agentbot",
           url.host() == "login",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let apiKey = components.queryItems?.first(where: { $0.name == "key" })?.value {
            // Confirm pairing with backend
            Task {
                await confirmPairing(code: apiKey)
                try? await auth.loginWithAPIKey(apiKey)
            }
            dismiss()
        } else if code.count >= 6 {
            Task {
                await confirmPairing(code: code)
                try? await auth.loginWithAPIKey(code)
            }
            dismiss()
        }
    }
    
    private func confirmPairing(code: String) async {
        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        struct ConfirmRequest: Codable {
            let code: String
            let deviceId: String
        }
        
        let body = ConfirmRequest(code: code, deviceId: deviceId)
        
        var request = URLRequest(url: URL(string: "https://agentbot.sh/api/pair/confirm")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(body)
        
        _ = try? await URLSession.shared.data(for: request)
    }
}

struct LoginQRScannerRepresentable: UIViewRepresentable {
    let onScanned: (String) -> Void
    
    func makeUIView(context: Context) -> LoginQRScannerUIView {
        let view = LoginQRScannerUIView()
        view.onScanned = onScanned
        return view
    }
    
    func updateUIView(_ uiView: LoginQRScannerUIView, context: Context) {}
}

@MainActor
class LoginQRScannerUIView: UIView, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    var onScanned: ((String) -> Void)?
    private nonisolated(unsafe) var session: AVCaptureSession?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let s = AVCaptureSession()
        self.session = s
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        if s.canAddInput(input) { s.addInput(input) }
        let output = AVCaptureMetadataOutput()
        if s.canAddOutput(output) {
            s.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        let preview = AVCaptureVideoPreviewLayer(session: s)
        preview.videoGravity = .resizeAspectFill
        layer.addSublayer(preview)
        DispatchQueue.global(qos: .userInitiated).async { s.startRunning() }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first?.frame = bounds
    }
    
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = obj.stringValue else { return }
        session?.stopRunning()
        Task { @MainActor in onScanned?(value) }
    }
}

#Preview {
    LoginView()
}
