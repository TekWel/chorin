import Foundation
import Supabase

// MARK: - SupabaseManager

final class SupabaseManager {
    static let shared = SupabaseManager()

    // TODO: Replace with your Supabase project URL
    private let supabaseURL = "https://kfacznslshhxrcpxdjdj.supabase.co"
    // TODO: Replace with your Supabase anon key
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtmYWN6bnNsc2hoeHJjcHhkamRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3Mjk2NzcsImV4cCI6MjA4NzMwNTY3N30.IR5DL6VzH26law9K1P-K0vFJ5GnnkCVz90OjrPREkTs"

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseAnonKey
        )
    }
}
