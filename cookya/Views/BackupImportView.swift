import SwiftUI
import UniformTypeIdentifiers

struct BackupImportView: View {
    @State private var pickedData: Data?
    @State private var pickedFilename: String?
    @State private var decodedBackup: CookyaExportBackup?
    @State private var decodeError: String?

    @State private var showFilePicker = false
    @State private var showConfirmReplaceAll = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                Button("Choose backup file") {
                    showFilePicker = true
                }
            } header: {
                Text("Import")
            } footer: {
                Text("Import replaces local Cookya data on this device with the selected backup file.")
            }

            if let decodedBackup {
                Section("Backup summary") {
                    if let pickedFilename {
                        Text(pickedFilename)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("Created: \(decodedBackup.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .foregroundStyle(.secondary)
                    Text("Version: \(decodedBackup.version)")
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Import (replace all)", role: .destructive) {
                        showConfirmReplaceAll = true
                    }
                }
            }

            if let decodeError {
                Section("Status") {
                    Text(decodeError)
                        .foregroundStyle(.secondary)
                }
            } else if let statusMessage {
                Section("Status") {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Import backup")
        .onAppear { AppLogger.screen("BackupImport") }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.json],
            allowsMultipleSelection: false
        ) { result in
            handlePickedFile(result)
        }
        .confirmationDialog(
            "Replace all local Cookya data with this backup?",
            isPresented: $showConfirmReplaceAll,
            titleVisibility: .visible
        ) {
            Button("Replace all data", role: .destructive) {
                applyReplaceAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will overwrite pantry, grocery, saved recipes, cooked history, profile, and known items on this device.")
        }
    }

    private func handlePickedFile(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            guard let url = urls.first else { return }
            pickedFilename = url.lastPathComponent

            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }

            let data = try Data(contentsOf: url)
            pickedData = data

            switch CookyaBackupCodec.decode(data) {
            case .success(let backup):
                decodedBackup = backup
                decodeError = nil
                statusMessage = nil
                AppLogger.action(
                    "backup_import_selected",
                    metadata: ["version": String(backup.version), "file": url.lastPathComponent]
                )
            case .failure(let error):
                decodedBackup = nil
                decodeError = error.errorDescription ?? "Backup file could not be read."
                AppLogger.action(
                    "backup_import_decode_failed",
                    metadata: ["file": url.lastPathComponent, "error": String(describing: error)]
                )
            }
        } catch {
            decodedBackup = nil
            decodeError = "Could not read the selected file."
            AppLogger.action("backup_import_read_failed", metadata: ["error": String(describing: error)])
        }
    }

    private func applyReplaceAll() {
        guard let decodedBackup else { return }
        let result = BackupImportApplier.applyReplaceAll(decodedBackup)
        NotificationCenter.default.post(name: .cookyaBackupImported, object: nil)
        statusMessage = "Imported."
        AppLogger.action(
            "backup_import_applied",
            metadata: ["version": String(decodedBackup.version), "keys": result.restoredKeys.joined(separator: ",")]
        )
    }
}

struct BackupImportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackupImportView()
        }
    }
}

