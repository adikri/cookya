import SwiftUI
import UniformTypeIdentifiers

struct BackupExportView: View {
    @State private var shareURL: URL?
    @State private var lastErrorMessage: String?

    var body: some View {
        Form {
            Section {
                Button("Export backup") {
                    exportBackup()
                }
            } header: {
                Text("Export")
            } footer: {
                Text("Exports your pantry, grocery list, saved recipes, cooked history, profile, and known items into a file you can save in Files or iCloud Drive.")
            }

            if let lastErrorMessage {
                Section("Status") {
                    Text(lastErrorMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Backup")
        .onAppear { AppLogger.screen("BackupExport") }
        .sheet(isPresented: Binding(get: { shareURL != nil }, set: { if !$0 { shareURL = nil } })) {
            if let shareURL {
                ShareSheet(activityItems: [shareURL])
            }
        }
    }

    private func exportBackup() {
        do {
            let snapshot = CookyaBackupCodec.makeSnapshot()
            let backup = CookyaExportBackup(snapshot: snapshot)
            let data = try CookyaBackupCodec.encode(backup)

            let filename = "cookya-backup-v1-\(Self.timestampString()).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)

            shareURL = url
            lastErrorMessage = nil
            AppLogger.action("backup_export_ready", metadata: ["version": String(backup.version), "file": filename])
        } catch {
            lastErrorMessage = "Could not export backup."
            AppLogger.action("backup_export_failed", metadata: ["error": String(describing: error)])
        }
    }

    private static func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return formatter.string(from: .now)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        BackupExportView()
    }
}

