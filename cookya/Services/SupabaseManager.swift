import Foundation
import Supabase

@MainActor
final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let config = AppConfig.live
        client = SupabaseClient(
            supabaseURL: config.supabaseURL,
            supabaseKey: config.supabasePublishableKey
        )
        AppLogger.action("supabase_client_initialized", screen: "SupabaseManager", metadata: ["url": config.supabaseURL.host ?? "unknown"])
    }
}
