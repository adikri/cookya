import Foundation

nonisolated
struct AppLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let timestampUTC: String
    let timestampLocal: String
    let sessionID: String
    let event: String
    let screen: String?
    let metadata: [String: String]

    init(
        id: UUID = UUID(),
        timestampUTC: String,
        timestampLocal: String,
        sessionID: String,
        event: String,
        screen: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.timestampUTC = timestampUTC
        self.timestampLocal = timestampLocal
        self.sessionID = sessionID
        self.event = event
        self.screen = screen
        self.metadata = metadata
    }

    var timestamp: String {
        timestampLocal
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case timestampUTC
        case timestampLocal
        case sessionID
        case event
        case screen
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sessionID = try container.decode(String.self, forKey: .sessionID)
        event = try container.decode(String.self, forKey: .event)
        screen = try container.decodeIfPresent(String.self, forKey: .screen)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]

        if let utc = try container.decodeIfPresent(String.self, forKey: .timestampUTC),
           let local = try container.decodeIfPresent(String.self, forKey: .timestampLocal) {
            timestampUTC = utc
            timestampLocal = local
        } else {
            let legacyTimestamp = try container.decode(String.self, forKey: .timestamp)
            timestampUTC = legacyTimestamp
            timestampLocal = legacyTimestamp
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestampUTC, forKey: .timestampUTC)
        try container.encode(timestampLocal, forKey: .timestampLocal)
        try container.encode(sessionID, forKey: .sessionID)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(screen, forKey: .screen)
        try container.encode(metadata, forKey: .metadata)
    }
}

nonisolated
struct AppLogSession: Identifiable, Hashable {
    let id: String
    let fileURL: URL
    let createdAt: Date
    let entryCount: Int

    var filePath: String { fileURL.path }

    var title: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: createdAt)
    }
}

actor AppLogger {
    static let shared = AppLogger()
    nonisolated static let logsDirectoryName = "cookya-debug-sessions"

    nonisolated static var logsDirectoryURL: URL {
        let baseURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return baseURL.appendingPathComponent(logsDirectoryName, isDirectory: true)
    }

    nonisolated static var logsDirectoryPath: String {
        logsDirectoryURL.path
    }

    nonisolated static func log(_ message: String, metadata: [String: String] = [:]) {
        Task {
            await shared.write(event: message, screen: nil, metadata: metadata)
        }
    }

    nonisolated static func screen(_ screen: String, metadata: [String: String] = [:]) {
        Task {
            await shared.write(event: "screen_view", screen: screen, metadata: metadata)
        }
    }

    nonisolated static func action(_ event: String, screen: String? = nil, metadata: [String: String] = [:]) {
        Task {
            await shared.write(event: event, screen: screen, metadata: metadata)
        }
    }

    private let sessionID: String
    private let sessionCreatedAt: Date
    private let sessionFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let utcFormatter: ISO8601DateFormatter
    private let localFormatter: DateFormatter

    private init() {
        self.sessionID = UUID().uuidString
        self.sessionCreatedAt = Date()
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.utcFormatter = ISO8601DateFormatter()
        self.localFormatter = DateFormatter()
        self.localFormatter.dateStyle = .medium
        self.localFormatter.timeStyle = .medium
        self.localFormatter.timeZone = .current

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let safeTimestamp = formatter.string(from: sessionCreatedAt)
        self.sessionFileURL = Self.logsDirectoryURL
            .appendingPathComponent("session-\(safeTimestamp)-\(sessionID).jsonl")

        ensureLogsDirectoryExists()
    }

    func currentSessionID() -> String {
        sessionID
    }

    func currentSessionFilePath() -> String {
        sessionFileURL.path
    }

    func currentSessionFileURL() -> URL {
        sessionFileURL
    }

    func readEntries(limit: Int? = nil) -> [AppLogEntry] {
        readEntries(from: sessionFileURL, limit: limit)
    }

    func readEntries(for session: AppLogSession, limit: Int? = nil) -> [AppLogEntry] {
        readEntries(from: session.fileURL, limit: limit)
    }

    func rawContents(for session: AppLogSession) -> String {
        (try? String(contentsOf: session.fileURL, encoding: .utf8)) ?? ""
    }

    func listSessions() -> [AppLogSession] {
        ensureLogsDirectoryExists()

        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: Self.logsDirectoryURL,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension == "jsonl" }
            .compactMap { url in
                let values = try? url.resourceValues(forKeys: [.creationDateKey])
                let createdAt = values?.creationDate ?? sessionCreatedAt
                let entries = readEntries(from: url, limit: nil)
                return AppLogSession(
                    id: url.deletingPathExtension().lastPathComponent,
                    fileURL: url,
                    createdAt: createdAt,
                    entryCount: entries.count
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func deleteSession(_ session: AppLogSession) {
        guard FileManager.default.fileExists(atPath: session.fileURL.path) else { return }
        do {
            try FileManager.default.removeItem(at: session.fileURL)
        } catch {
            print("Cookya logger session delete failed: \(error)")
        }
    }

    func clearAllSessions() {
        let sessions = listSessions()
        for session in sessions {
            deleteSession(session)
        }
    }

    nonisolated private func ensureLogsDirectoryExists() {
        if !FileManager.default.fileExists(atPath: Self.logsDirectoryURL.path) {
            do {
                try FileManager.default.createDirectory(at: Self.logsDirectoryURL, withIntermediateDirectories: true)
            } catch {
                print("Cookya logger failed to create directory: \(error)")
            }
        }
    }

    private func readEntries(from fileURL: URL, limit: Int? = nil) -> [AppLogEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let text = String(data: data, encoding: .utf8)
        else {
            return []
        }

        let parsed = text
            .split(separator: "\n")
            .compactMap { line -> AppLogEntry? in
                guard let lineData = line.data(using: .utf8) else { return nil }
                return try? decoder.decode(AppLogEntry.self, from: lineData)
            }

        if let limit {
            return Array(parsed.suffix(limit))
        }
        return parsed
    }

    private func write(event: String, screen: String?, metadata: [String: String]) {
        let now = Date()
        let entry = AppLogEntry(
            timestampUTC: utcFormatter.string(from: now),
            timestampLocal: localFormatter.string(from: now),
            sessionID: sessionID,
            event: event,
            screen: screen,
            metadata: metadata
        )

        guard let data = try? encoder.encode(entry) else {
            print("Cookya logger failed: encoding error")
            return
        }

        var line = data
        line.append(0x0A)

        if FileManager.default.fileExists(atPath: sessionFileURL.path) {
            do {
                let handle = try FileHandle(forWritingTo: sessionFileURL)
                try handle.seekToEnd()
                try handle.write(contentsOf: line)
                try handle.close()
            } catch {
                print("Cookya logger failed: \(error)")
            }
        } else {
            do {
                try line.write(to: sessionFileURL, options: .atomic)
            } catch {
                print("Cookya logger failed: \(error)")
            }
        }
    }
}
