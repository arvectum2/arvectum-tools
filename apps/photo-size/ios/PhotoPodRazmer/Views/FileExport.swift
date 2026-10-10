import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data, .jpeg, .png, .heic, .pdf] }
    static var writableContentTypes: [UTType] { [.data, .jpeg, .png, .heic, .pdf] }
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
