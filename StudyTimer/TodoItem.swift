import Foundation

struct TodoItem: Codable {
    var id: UUID
    var title: String
    var isDone: Bool
    var memo: String?
    
    init(id: UUID = UUID(), title: String, isDone: Bool, memo: String? = nil) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.memo = memo
    }
}

