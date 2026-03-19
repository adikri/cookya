import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct DebugLogsView: View {
    @State private var sessions: [AppLogSession] = []
    @State private var currentSessionID = ""
    @State private var currentSessionFilePath = ""

    var body: some View {
        List {
            Section("Current Session") {
                LabeledContent("Session ID", value: currentSessionID.isEmpty ? "Loading..." : currentSessionID)
                LabeledContent("Logs folder", value: AppLogger.logsDirectoryPath)
                    .lineLimit(2)
                    .font(.caption)

                if !currentSessionFilePath.isEmpty {
                    LabeledContent("Current file", value: currentSessionFilePath)
                        .lineLimit(2)
                        .font(.caption)
                }
            }

            Section("Sessions") {
                if sessions.isEmpty {
                    Text("No log sessions yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink {
                            DebugLogSessionDetailView(session: session)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(session.title)
                                        .font(.headline)
                                    Spacer()
                                    if session.id.contains(currentSessionID) {
                                        Text("Current")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.12), in: Capsule())
                                    }
                                }
                                Text("\(session.entryCount) events")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(session.filePath)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(1)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
            }

            Section {
                Button("Clear All Sessions", role: .destructive) {
                    Task {
                        await AppLogger.shared.clearAllSessions()
                        await loadSessions()
                    }
                }
            }
        }
        .navigationTitle("Debug Logs")
        .task {
            AppLogger.screen("DebugLogs")
            await loadSessions()
        }
        .refreshable {
            await loadSessions()
        }
    }

    private func loadSessions() async {
        sessions = await AppLogger.shared.listSessions()
        currentSessionID = await AppLogger.shared.currentSessionID()
        currentSessionFilePath = await AppLogger.shared.currentSessionFilePath()
    }

    private func deleteSessions(at offsets: IndexSet) {
        let sessionsToDelete = offsets.map { sessions[$0] }
        Task {
            for session in sessionsToDelete {
                await AppLogger.shared.deleteSession(session)
            }
            await loadSessions()
        }
    }
}

private struct DebugLogSessionDetailView: View {
    let session: AppLogSession

    @State private var entries: [AppLogEntry] = []
    @State private var copyConfirmation = ""

    var body: some View {
        List {
            Section("Session") {
                LabeledContent("Started", value: session.title)
                LabeledContent("Events", value: String(session.entryCount))
                LabeledContent("File", value: session.filePath)
                    .lineLimit(2)
                    .font(.caption)

                ShareLink(item: session.fileURL) {
                    Label("Export Session Log", systemImage: "square.and.arrow.up")
                }

                Button("Copy Session Contents") {
                    Task {
                        let contents = await AppLogger.shared.rawContents(for: session)
                        copyToPasteboard(contents)
                        copyConfirmation = "Full session copied."
                    }
                }

                Button("Copy Last 50 Events") {
                    Task {
                        let recentEntries = await AppLogger.shared.readEntries(for: session, limit: 50)
                        let text = recentEntries
                            .map { entry in
                                var lines: [String] = []
                                lines.append("[\(entry.timestampLocal)] \(entry.event)")
                                if let screen = entry.screen {
                                    lines.append("screen: \(screen)")
                                }
                                for item in entry.metadata.sorted(by: { $0.key < $1.key }) {
                                    lines.append("\(item.key): \(item.value)")
                                }
                                lines.append("utc: \(entry.timestampUTC)")
                                return lines.joined(separator: "\n")
                            }
                            .joined(separator: "\n\n")
                        copyToPasteboard(text)
                        copyConfirmation = "Last 50 events copied."
                    }
                }

                if !copyConfirmation.isEmpty {
                    Text(copyConfirmation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Events") {
                if entries.isEmpty {
                    Text("No log events in this session.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(entries.reversed()) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(entry.event)
                                    .font(.headline)
                                Spacer()
                                Text(entry.timestampLocal)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if let screen = entry.screen {
                                Text("Screen: \(screen)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if !entry.metadata.isEmpty {
                                ForEach(entry.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    Text("\(key): \(value)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text("UTC: \(entry.timestampUTC)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Session Log")
        .task {
            entries = await AppLogger.shared.readEntries(for: session, limit: 500)
        }
        .refreshable {
            entries = await AppLogger.shared.readEntries(for: session, limit: 500)
        }
    }

    private func copyToPasteboard(_ value: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        #endif
    }
}

#Preview {
    NavigationStack {
        DebugLogsView()
    }
}
