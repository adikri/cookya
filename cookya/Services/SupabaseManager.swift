import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let config = AppConfig.live

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        client = SupabaseClient(
            supabaseURL: config.supabaseURL,
            supabaseKey: config.supabasePublishableKey,
            options: SupabaseClientOptions(
                db: .init(encoder: encoder, decoder: decoder)
            )
        )
        AppLogger.action("supabase_client_initialized", screen: "SupabaseManager", metadata: ["url": config.supabaseURL.host ?? "unknown"])
    }
}
