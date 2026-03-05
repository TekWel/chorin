import Foundation
import Supabase

@Observable
final class AppState {
    var session: Session?
    var household: Household?
    var member: HouseholdMember?
    var isLoading: Bool = true

    var isAuthenticated: Bool { session != nil }
    var hasHousehold: Bool { household != nil }

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Bootstrap

    func bootstrap() async {
        isLoading = true
        defer { isLoading = false }

        do {
            session = try await supabase.auth.session
            if session != nil {
                await loadHouseholdAndMember()
            }
        } catch {
            session = nil
        }
    }

    func loadHouseholdAndMember() async {
        guard let userId = session?.user.id else { return }
        do {
            // Load the user's household membership
            let members: [HouseholdMember] = try await supabase
                .from("household_members")
                .select()
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let m = members.first {
                member = m
                // Load the household
                let households: [Household] = try await supabase
                    .from("households")
                    .select()
                    .eq("id", value: m.householdId.uuidString)
                    .limit(1)
                    .execute()
                    .value
                household = households.first
            } else {
                member = nil
                household = nil
            }
        } catch {
            print("Error loading household: \(error)")
        }
    }

    // MARK: - Auth

    func signOut() async {
        do {
            try await supabase.auth.signOut()
        } catch {
            print("Sign out error: \(error)")
        }
        session = nil
        household = nil
        member = nil
    }
}
