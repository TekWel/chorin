import Foundation

struct Household: Codable, Identifiable {
    let id: UUID
    let name: String
    let inviteCode: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case inviteCode = "invite_code"
        case createdAt = "created_at"
    }
}
