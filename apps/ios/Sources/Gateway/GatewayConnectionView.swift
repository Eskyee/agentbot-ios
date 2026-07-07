import SwiftUI
@preconcurrency import AVFoundation

struct GatewayConnectionView: View {
    @State private var showQRScanner = false
    @State private var showManualSetup = false
    @State private var manualHost = ""
    @State private var manualPort = ""
    @State private var isConnected = false
    @State private var connectionError: String?
    @State private var savedGateway: SavedGateway?
    
    struct SavedGateway: Codable {
        let host: String
        let port: Int
        let name: String?
        let connectedAt: Date
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let gateway = savedGateway {
                connectedGatewayView(gateway)
            } else {
                notConnectedView
            }
        }
        .navigationTitle("Gateway")
        .sheet(isPresented: $showQRScanner) {
            QRScannerSheet()
        }
        .sheet(isPresented: $showManualSetup) {
            manualSetupSheet
        }
        .task {
            await loadSavedGateway()
        }
    }
    
    private var notConnectedView: some View {
        VStack(spacing: 32) {
            Spacer(minLength: 60)
            
            VStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundStyle(AgentbotBrand.accent)
                
                Text("Connect Gateway")
                    .font(.largeTitle.bold())
                
                Text("Scan a QR code from your Agentbot gateway or continue with manual setup.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How to pair")
                    .font(.headline)
                Text("In your Agentbot chat, run")
                    .foregroundStyle(.secondary)
                Text("/pair qr")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                Text("Then scan the QR code here to connect this device.")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 32)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    showQRScanner = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("Scan QR Code")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AgentbotBrand.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button {
                    showManualSetup = true
                } label: {
                    Text("Set Up Manually")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundStyle(AgentbotBrand.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
            
            Text("No saved pairing found. In your Agentbot chat, run /pair qr, then scan the code here.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
                .padding(.bottom, 24)
        }
    }
    
    private func connectedGatewayView(_ gateway: SavedGateway) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.green)
                }
                
                Text("Connected")
                    .font(.title.bold())
                
                Text(gateway.name ?? "Agentbot Gateway")
                    .font(.headline)
                
                Text("\(gateway.host):\(gateway.port)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Connected \(gateway.connectedAt, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(role: .destructive) {
                    disconnectGateway()
                } label: {
                    Text("Disconnect")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button {
                    showManualSetup = true
                } label: {
                    Text("Reconnect to Different Gateway")
                        .font(.subheadline)
                        .foregroundStyle(AgentbotBrand.accent)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
    }
    
    private var manualSetupSheet: some View {
        NavigationStack {
            Form {
                Section("Gateway Address") {
                    TextField("Host", text: $manualHost)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    TextField("Port", text: $manualPort)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    if let error = connectionError {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    
                    Button("Connect") {
                        connectManually()
                    }
                    .disabled(manualHost.isEmpty || manualPort.isEmpty)
                }
            }
            .navigationTitle("Manual Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showManualSetup = false }
                }
            }
        }
    }
    
    private func connectManually() {
        guard let port = Int(manualPort) else {
            connectionError = "Invalid port number."
            return
        }
        
        let gateway = SavedGateway(
            host: manualHost,
            port: port,
            name: nil,
            connectedAt: Date()
        )
        
        saveGateway(gateway)
        savedGateway = gateway
        showManualSetup = false
        connectionError = nil
    }
    
    private func disconnectGateway() {
        UserDefaults.standard.removeObject(forKey: "agentbot.savedGateway")
        savedGateway = nil
    }
    
    private func loadSavedGateway() async {
        guard let data = UserDefaults.standard.data(forKey: "agentbot.savedGateway"),
              let gateway = try? JSONDecoder().decode(SavedGateway.self, from: data) else {
            return
        }
        savedGateway = gateway
    }
    
    private func saveGateway(_ gateway: SavedGateway) {
        if let data = try? JSONEncoder().encode(gateway) {
            UserDefaults.standard.set(data, forKey: "agentbot.savedGateway")
        }
    }
}

struct QRScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var cameraPermission = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if cameraPermission {
                    QRScannerViewRepresentable { code in
                        scannedCode = code
                        handleScannedCode(code)
                    }
                    .ignoresSafeArea()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Camera access is required to scan QR codes.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Grant Access") {
                            requestCameraAccess()
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
                await checkCameraPermission()
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        // Handle login QR codes from agentbot.sh
        // Format: agentbot://login?key=YOUR_API_KEY
        if let url = URL(string: code),
           url.scheme == "agentbot",
           url.host() == "login",
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let apiKey = components.queryItems?.first(where: { $0.name == "key" })?.value {
            
            Task {
                // Confirm pairing with backend
                await confirmPairing(code: apiKey)
                // Login with the API key
                try? await AuthManager.shared.loginWithAPIKey(apiKey)
            }
            dismiss()
            return
        }
        
        // Handle gateway pairing QR codes
        // Format: agentbot://gateway?host=X&port=Y
        guard let url = URL(string: code),
              url.scheme == "agentbot",
              url.host() == "gateway",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.queryItems?.first(where: { $0.name == "host" })?.value,
              let portStr = components.queryItems?.first(where: { $0.name == "port" })?.value,
              let port = Int(portStr)
        else {
            return
        }
        
        let gateway = GatewayConnectionView.SavedGateway(
            host: host,
            port: port,
            name: components.queryItems?.first(where: { $0.name == "name" })?.value,
            connectedAt: Date()
        )
        
        if let data = try? JSONEncoder().encode(gateway) {
            UserDefaults.standard.set(data, forKey: "agentbot.savedGateway")
        }
        
        dismiss()
    }
    
    private func checkCameraPermission() async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        await MainActor.run {
            cameraPermission = status == .authorized
        }
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                cameraPermission = granted
            }
        }
    }
    
    private func requestCameraAccess() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                cameraPermission = granted
            }
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

struct QRScannerViewRepresentable: UIViewRepresentable {
    let onScanned: (String) -> Void
    
    func makeUIView(context: Context) -> QRScannerUIView {
        let view = QRScannerUIView()
        view.onScanned = onScanned
        return view
    }
    
    func updateUIView(_ uiView: QRScannerUIView, context: Context) {}
}

@preconcurrency @MainActor
class QRScannerUIView: UIView, AVCaptureMetadataOutputObjectsDelegate {
    var onScanned: ((String) -> Void)?
    private nonisolated(unsafe) var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        self.captureSession = session
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        layer.addSublayer(preview)
        self.previewLayer = preview
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
    }
    
    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        
        captureSession?.stopRunning()
        
        Task { @MainActor in
            onScanned?(value)
        }
    }
}
