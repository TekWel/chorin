import Foundation

struct Chore: Codable, Identifiable {
    let id: UUID
    let householdId: UUID
    let name: String
    let value: Decimal
    let icon: String
    let isActive: Bool
    let createdByUserId: UUID?
    let validationStatus: String?   // "auto" | "requires_parent"
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case householdId = "household_id"
        case name
        case value
        case icon
        case isActive = "is_active"
        case createdByUserId = "created_by_user_id"
        case validationStatus = "validation_status"
        case createdAt = "created_at"
    }
}

// Returned by get_todays_chores_for_current_user RPC
struct ChoreWithCompletion: Codable, Identifiable {
    let id: UUID
    let name: String
    let value: Decimal
    let icon: String
    let completionId: UUID?
    let isCompleted: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case value
        case icon
        case completionId = "completion_id"
        case isCompleted = "is_completed"
    }
}
