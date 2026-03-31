import Foundation

struct ButtonMode: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var actions: [String]

    func label(for buttonIndex: Int) -> String {
        guard buttonIndex < actions.count,
              let action = ActionCatalog.find(actions[buttonIndex]) else {
            return "---"
        }
        return action.label
    }
}
