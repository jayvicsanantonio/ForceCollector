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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionTitle(
                    eyebrow: "Fast Add",
                    title: "Barcode Scanner",
                    subtitle: "Scan a Black Series package to match a seeded figure or fall back to manual search."
                )

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Live scanner")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        scannerSurface
                    }
                }

                CollectorPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Manual fallback")
                            .font(.system(.headline, design: .rounded, weight: .semibold))

                        TextField("Paste a barcode or figure name", text: $manualCode)
                            .textInputAutocapitalization(.never)
                            .padding(14)
                            .background(AppTheme.elevatedSurface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Button("Search or record scan") {
                            submit(code: manualCode)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                    }
                }

                if let currentResult {
                    ScanResultsView(result: currentResult, store: store)
                }
            }
            .padding(20)
        }
        .background(AppTheme.background)
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var scannerSurface: some View {
        #if targetEnvironment(simulator)
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(AppTheme.elevatedSurface)
            .frame(height: 280)
            .overlay {
                VStack(spacing: 16) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.gold)
                    Text("Simulator mode")
                        .font(AppTheme.displayFont(size: 24, weight: .bold))
                    Text("Use the manual fallback below. Camera capture is available on a physical iPhone build.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }
            }
        #else
        BarcodeScannerCameraView { code in
            submit(code: code)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
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
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(
                eyebrow: "Result",
                title: result.matchedFigure == nil ? "Scan Results" : "Matched Figure",
                subtitle: result.matchedFigure == nil ? "No exact barcode hit. Here are the closest seeded options." : "The seeded catalog found a matching Black Series figure."
            )

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
