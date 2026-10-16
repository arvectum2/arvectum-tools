import SwiftUI

/// Capture-first entry point for both people with and without an Apple Watch.
/// Saving audio never depends on the library UI or on any AI service.
struct ContentView: View {
    @EnvironmentObject private var store: PhoneStore
    @State private var showingLibrary = false

    var body: some View {
        Group {
            if showingLibrary {
                RecordingLibraryView(
                    openCaptureHome: { showingLibrary = false }
                )
            } else {
                QuickCaptureHomeView(
                    recordingsCount: store.recordings.count + store.localNotes.count,
                    startRecording: { store.beginPhoneCapture() },
                    startVideo: { store.showVideoCapture = true },
                    newText: { store.showTextCapture = true },
                    openLibrary: { showingLibrary = true }
                )
            }
        }
        .sheet(isPresented: $store.showPhoneCapture) {
            PhoneRecordingSheet(recorder: store.phoneRecorder)
        }
        .sheet(isPresented: $store.showTextCapture) {
            TextNoteSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.showVideoCapture) {
            VideoCaptureHost()
                .environmentObject(store)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let notice = store.videoRecoveryNotice {
                HStack(spacing: 10) {
                    Image(systemName: "externaldrive.badge.checkmark")
                    Text(notice)
                        .font(.caption)
                    Spacer(minLength: 4)
                    Button {
                        Task { await store.recoverInterruptedVideos() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel(
                        CaptureBrand.text("Повторить восстановление", "Retry video recovery")
                    )
                    Button {
                        store.videoRecoveryNotice = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(CaptureBrand.text("Скрыть", "Dismiss"))
                }
                .padding(10)
                .background(.thinMaterial)
            }
        }
        .alert(CaptureBrand.name, isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
