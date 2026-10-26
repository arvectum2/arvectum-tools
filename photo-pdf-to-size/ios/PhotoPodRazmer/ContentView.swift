import ArvectumCore
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
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

            // Preserve the native ad viewport alongside the 44pt privacy footer.
            VStack(spacing: 2) {
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
                                onShare: { shareURL = pdfResult.outputURL },
                                onBack: model.backToSelection
                            )
                            ResultScreenAdSlot()
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 4) {
                            ArvectumAdaptiveContentStack(minimumPaneWidth: 300, spacing: 16, showTrailingInCompact: false) {
                                Group {
                                    if model.inputKind == .photo {
                                        MainTaskCard(pickerItem: $pickerItem)
                                    } else {
                                        PDFTaskCard()
                                    }
                                }
                            } trailing: {
                                AdaptiveSourcePreview()
                            }
                            MainScreenNativeAdSlot(session: mainNativeAdSession)
                        }
                        .frame(maxWidth: 1120)
                        .frame(maxWidth: .infinity)
                    }
                }

                // The save action must remain visible even when the result
                // preview is taller than the screen or an ad is displayed.
                // It is outside the scroll view and above the footer.
                if model.result != nil || model.pdfResult != nil {
                    Button {
                        if model.pdfResult != nil {
                            beginPDFExport()
                        } else {
                            beginExport()
                        }
                    } label: {
                        Label(tr("Сохранить файл"), systemImage: "square.and.arrow.down")
                            .font(.headline)
                            // Keep the sticky CTA readable and within the
                            // viewport at AXXXL; don't constrain result body.
                            .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .accessibility1 : dynamicTypeSize)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: ArvectumDesignMetrics.preferredControlHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ArvectumSemanticColors.actionForeground)
                    .background(
                        ArvectumSemanticColors.actionBackground,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .accessibilityIdentifier("result-save-primary")
                    .padding(.vertical, 8)

                    // State changes only after fileExporter reports success;
                    // never claim a file was saved when the picker is canceled.
                    if model.saved {
                        Label(tr("Файл сохранён"), systemImage: "checkmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.arvectumAccentText)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .accessibilityIdentifier("export-success")
                    }
                }

                HStack(spacing: 6) {
                    // The brand already appears in the header; omit the
                    // redundant website prefix, which stole space from the
                    // privacy action at the simulated largest Dynamic Type.
                    Button {
                        showingAdPrivacySettings = true
                    } label: {
                        Text(tr("Реклама в приложении"))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ad-privacy-settings-button")
                    // Short visible title remains the spoken button label;
                    // VoiceOver adds the destination's privacy details as a hint.
                    .accessibilityHint(tr("Реклама и конфиденциальность"))
                }
                // Keep the privacy control a full-size touch target at AXXXL.
                .font(.caption.weight(.semibold))
                .dynamicTypeSize(dynamicTypeSize.isAccessibilitySize ? .xxxLarge : dynamicTypeSize)
                .foregroundStyle(.secondary)
                .tracking(0.3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 44)
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
            if !ProcessInfo.processInfo.arguments.contains("--store-screenshot-clean") {
                mainNativeAdSession.prefetch()
            }
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
                if !isCanceledFileExport(error) {
                    model.markSaveFailed(error)
                }
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
