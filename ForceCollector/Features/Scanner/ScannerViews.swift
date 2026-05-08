@preconcurrency import AVFoundation
import SwiftData
import SwiftUI

struct ScanView: View {
    let store: CollectionStore

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CatalogFigure.sortIndex) private var figures: [CatalogFigure]

    @State private var manualCode = ""
    @State private var currentResult: ScanLookupResult?
    private let scannerService = ScannerService()

    var body: some View {
        ZStack {
            StitchRemoteImage(urlString: StitchAsset.scanner, contentMode: .fill)
                .ignoresSafeArea()
                .opacity(0.52)
                .blendMode(.overlay)

            LinearGradient(
                colors: [.black.opacity(0.62), .clear, AppTheme.background.opacity(0.94)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 48, height: 48)
                        .background(.black.opacity(0.42), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))

                    Spacer()

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 48, height: 48)
                        .background(.black.opacity(0.42), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                scannerSurface

                Text("Align barcode within frame")
                    .font(AppTheme.labelFont(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(.top, 30)

                Spacer()

                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 18, weight: .bold))
                        TextField("Enter code manually", text: $manualCode)
                            .textInputAutocapitalization(.never)
                            .font(AppTheme.labelFont(size: 15, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.scannerCyan)
                    .padding(14)
                    .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppTheme.scannerCyan.opacity(0.8), lineWidth: 2))

                    Button {
                        submit(code: manualCode)
                    } label: {
                        Text("Search or Record Scan")
                            .font(AppTheme.labelFont(size: 13, weight: .bold))
                            .tracking(1.3)
                            .textCase(.uppercase)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.scannerCyan, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .foregroundStyle(AppTheme.background)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Session Scans: \(currentResult == nil ? 0 : 1)")
                    }
                    .font(AppTheme.labelFont(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.62))
                    .tracking(1.2)
                    .textCase(.uppercase)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, currentResult == nil ? 112 : 16)
            }

            if let currentResult {
                VStack {
                    Spacer()
                    ScanResultsView(result: currentResult, store: store)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 96)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(AppTheme.background)
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var scannerSurface: some View {
        #if targetEnvironment(simulator)
        ScannerHUDFrame()
        #else
        BarcodeScannerCameraView { code in
            submit(code: code)
        }
        .frame(width: 288, height: 288)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(ScannerHUDFrame())
        #endif
    }

    private func submit(code: String) {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        let result = scannerService.resolveScan(code: trimmed, in: figures)
        currentResult = result
        try? store.recordScan(code: trimmed, matchedFigureID: result.matchedFigure?.id, query: trimmed, context: modelContext)
        manualCode = ""
    }
}

struct ScanResultsView: View {
    let result: ScanLookupResult
    let store: CollectionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: result.matchedFigure == nil ? "questionmark.circle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.scannerCyan)
                Text(result.matchedFigure == nil ? "Closest Matches" : "Target Identified")
                    .font(AppTheme.labelFont(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.scannerCyan)
                    .tracking(1.1)
                    .textCase(.uppercase)
                Spacer()
            }

            if let matchedFigure = result.matchedFigure {
                NavigationLink {
                    FigureDetailView(figure: matchedFigure, store: store)
                } label: {
                    FigureHeroCard(figure: matchedFigure, owned: false, wishlisted: false)
                }
                .buttonStyle(.plain)
            } else if result.suggestedFigures.isEmpty {
                EmptyCollectorState(
                    title: "No close seeded match",
                    message: "This barcode isn’t in the starter catalog yet. You can reseed later as the catalog grows.",
                    symbol: "questionmark.app.dashed"
                )
            } else {
                ForEach(result.suggestedFigures, id: \.id) { figure in
                    NavigationLink {
                        FigureDetailView(figure: figure, store: store)
                    } label: {
                        CollectorPanel {
                            HStack(spacing: 14) {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: figure.accentHex), AppTheme.elevatedSurface],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 82, height: 82)
                                    .overlay {
                                        Image(systemName: figure.symbol)
                                            .font(.system(size: 26, weight: .black))
                                            .foregroundStyle(.white.opacity(0.92))
                                    }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(figure.name)
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                    Text(figure.subtitle)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(AppTheme.secondaryText)
                                    Text(figure.wave)
                                        .font(.system(.footnote, design: .rounded, weight: .medium))
                                        .foregroundStyle(AppTheme.gold)
                                }
                                Spacer()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(AppTheme.deepPanel.opacity(0.96), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppTheme.scannerCyan.opacity(0.2), lineWidth: 1))
    }
}

private struct ScannerHUDFrame: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.scannerCyan.opacity(0.35), lineWidth: 1)
                .frame(width: 288, height: 288)

            Rectangle()
                .fill(AppTheme.scannerCyan)
                .frame(width: 288, height: 2)
                .shadow(color: AppTheme.scannerCyan, radius: 12)
                .offset(y: -56)

            ForEach(HUDCorner.allCases, id: \.self) { corner in
                HUDCornerShape(corner: corner)
                    .stroke(AppTheme.scannerCyan, style: StrokeStyle(lineWidth: 4, lineCap: .square, lineJoin: .miter))
                    .frame(width: 34, height: 34)
                    .position(corner.position(in: CGSize(width: 288, height: 288)))
            }
        }
        .frame(width: 288, height: 288)
    }
}

private enum HUDCorner: CaseIterable {
    case topLeft, topRight, bottomRight, bottomLeft

    func position(in size: CGSize) -> CGPoint {
        switch self {
        case .topLeft: CGPoint(x: 17, y: 17)
        case .topRight: CGPoint(x: size.width - 17, y: 17)
        case .bottomRight: CGPoint(x: size.width - 17, y: size.height - 17)
        case .bottomLeft: CGPoint(x: 17, y: size.height - 17)
        }
    }
}

private struct HUDCornerShape: Shape {
    let corner: HUDCorner

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch corner {
        case .topLeft:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        case .topRight:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        case .bottomRight:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        case .bottomLeft:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        }
        return path
    }
}

struct BarcodeScannerCameraView: UIViewRepresentable {
    let onDetect: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDetect: onDetect)
    }

    func makeUIView(context: Context) -> ScannerPreviewView {
        let view = ScannerPreviewView()
        context.coordinator.configureIfNeeded(for: view)
        return view
    }

    func updateUIView(_ uiView: ScannerPreviewView, context: Context) {
        context.coordinator.updatePreviewFrame(for: uiView)
    }

    @MainActor
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        private let session = AVCaptureSession()
        private let onDetect: (String) -> Void
        private var isConfigured = false

        init(onDetect: @escaping (String) -> Void) {
            self.onDetect = onDetect
        }

        func configureIfNeeded(for view: ScannerPreviewView) {
            guard isConfigured == false else {
                updatePreviewFrame(for: view)
                return
            }
            isConfigured = true

            guard let videoDevice = AVCaptureDevice.default(for: .video),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoInput)
            else {
                return
            }

            session.addInput(videoInput)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.ean8, .ean13, .pdf417, .code128, .qr]

            view.previewLayer.session = session
            view.previewLayer.videoGravity = .resizeAspectFill
            updatePreviewFrame(for: view)

            session.startRunning()
        }

        func updatePreviewFrame(for view: ScannerPreviewView) {
            view.previewLayer.frame = view.bounds
        }

        nonisolated func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue
            else {
                return
            }

            Task { @MainActor in
                session.stopRunning()
                onDetect(code)
                try? await Task.sleep(for: .seconds(1.2))
                if session.isRunning == false {
                    session.startRunning()
                }
            }
        }
    }
}

final class ScannerPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        let overlay = UIView()
        overlay.backgroundColor = .clear
        overlay.layer.borderColor = UIColor.white.withAlphaComponent(0.22).cgColor
        overlay.layer.borderWidth = 2
        overlay.layer.cornerRadius = 24
        overlay.translatesAutoresizingMaskIntoConstraints = false
        addSubview(overlay)

        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            overlay.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            overlay.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            overlay.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -40)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
