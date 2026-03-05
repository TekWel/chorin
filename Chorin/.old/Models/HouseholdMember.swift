import Foundation

struct HouseholdMember: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let userId: UUID
    let role: String          // "parent" | "child"
    let createdAt: Date

    var isParent: Bool { role == "parent" }

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case userId = "user_id"
        case role
        case createdAt = "created_at"
    }
}
