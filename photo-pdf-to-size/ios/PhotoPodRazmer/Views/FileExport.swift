import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// A user's Cancel action in the system Files picker is not a failed
/// export. Keep genuine IO errors visible while ignoring this one condition.
func isCanceledFileExport(_ error: Error) -> Bool {
    let value = error as NSError
    return value.domain == NSCocoaErrorDomain
        && value.code == NSUserCancelledError
}

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
