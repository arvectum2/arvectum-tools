import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

let fileSizePresets: [(Int64, String)] = [
    (100_000, "100 КБ"),
    (500_000, "500 КБ"),
    (1_000_000, "1 МБ"),
    (2_000_000, "2 МБ"),
    (5_000_000, "5 МБ")
]

let pixelPresets: [(Int, String)] = [
    (600, "600 px"),
    (450, "450 px"),
    (300, "300 px")
]

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var exporting = false
    @State private var exportDocument = ExportDocument(data: Data())
    @State private var exportFilename = "file.dat"
    @State private var exportContentType: UTType = .data
    @State private var shareURL: URL?
    @State private var showingAdPrivacySettings = false
    @StateObject private var mainNativeAdSession = NativeAdSession()

    var body: some View {
        ZStack {
            Color.arvectumBackground.ignoresSafeArea()

            VStack(spacing: 6) {
                BrandHeader(
                    showHome: model.result != nil || model.pdfResult != nil,
                    onHome: model.backToSelection
                )

                if model.result == nil && model.pdfResult == nil {
                    ModeSelector(
                        kind: model.inputKind,
                        mode: model.mode,
                        onPhotoMode: {
                            model.setInputKind(.photo)
                            model.setMode($0)
                        },
                        onPDF: { model.setInputKind(.pdf) }
                    )
                }

                if let result = model.result {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 6) {
                            ResultCard(
                                result: result,
                                onSave: beginExport,
                                onSavePrintSheet: beginPrintSheetExport,
                                onShare: { shareURL = result.outputURL },
                                onBack: model.backToSelection
                            )
                            ResultScreenAdSlot()
                        }
                    }
                } else if let pdfResult = model.pdfResult {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 6) {
                            PDFResultCard(
                                result: pdfResult,
                                onSave: beginPDFExport,
                                onShare: { shareURL = pdfResult.outputURL },
                                onBack: model.backToSelection
                            )
                            ResultScreenAdSlot()
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 4) {
                            if model.inputKind == .photo {
                                MainTaskCard(pickerItem: $pickerItem)
                            } else {
                                PDFTaskCard()
                            }
                            MainScreenNativeAdSlot(session: mainNativeAdSession)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Text("Arvectum.com")
                    Text("·")
                    Button(tr("Реклама и конфиденциальность")) {
                        showingAdPrivacySettings = true
                    }
                    .buttonStyle(.plain)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.3)
                .frame(height: (model.result == nil && model.pdfResult == nil) ? 24 : 16)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("app-footer")
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 0)

            if model.isWorking {
                Color.black.opacity(0.12).ignoresSafeArea()
                ProgressView()
                    .controlSize(.large)
                    .tint(.arvectumMint)
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .onAppear {
            mainNativeAdSession.prefetch()
        }
        .sheet(isPresented: $showingAdPrivacySettings) {
            AdConsentSheet { value in
                AdSDK.setUserConsent(value)
                showingAdPrivacySettings = false
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onChange(of: pickerItem) { _, newValue in
            model.selectPhoto(newValue)
        }
        .alert("Фото и PDF под размер", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $model.passportCropOpen) {
            if let source = model.source {
                PassportCropView(
                    image: source.image,
                    preset: model.documentPreset,
                    onCancel: { model.passportCropOpen = false },
                    onConfirm: model.preparePassport
                )
            }
        }
        .fileExporter(
            isPresented: $exporting,
            document: exportDocument,
            contentType: exportContentType,
            defaultFilename: exportFilename
        ) { result in
            switch result {
            case .success:
                model.markSaved(true)
            case .failure(let error):
                model.markSaveFailed(error)
            }
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL {
                ShareSheet(items: [shareURL])
            }
        }
    }

    private func beginExport() {
        guard let result = model.result,
              let data = try? Data(contentsOf: result.outputURL) else {
            model.errorMessage = tr("Не получилось сохранить файл.")
            return
        }
        exportDocument = ExportDocument(data: data)
        exportFilename = result.suggestedFileName
        exportContentType = result.contentType
        exporting = true
    }

    private func beginPDFExport() {
        guard let result = model.pdfResult,
              let data = try? Data(contentsOf: result.outputURL) else {
            model.errorMessage = tr("Не получилось сохранить файл.")
            return
        }
        exportDocument = ExportDocument(data: data)
        exportFilename = result.suggestedFileName
        exportContentType = .pdf
        exporting = true
    }

    private func beginPrintSheetExport() {
        guard let sheet = model.result?.printSheet,
              let data = try? Data(contentsOf: sheet.outputURL) else {
            model.errorMessage = tr("Не получилось подготовить лист для печати.")
            return
        }
        exportDocument = ExportDocument(data: data)
        exportFilename = sheet.suggestedFileName
        exportContentType = .jpeg
        exporting = true
    }
}
