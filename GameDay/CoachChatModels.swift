import Foundation

struct CoachChatMessage: Identifiable, Hashable, Sendable {
    enum Role: String, Sendable {
        case athlete
        case coach

        var title: String {
            switch self {
            case .athlete: return "You"
            case .coach: return "Coach AI"
            }
        }
    }

    let id: UUID
    let role: Role
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), role: Role, text: String, timestamp: Date = .now) {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
    }
}
