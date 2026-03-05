import Foundation

struct Ingredient: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var quantity: String

    init(id: UUID = UUID(), name: String, quantity: String = "") {
        self.id = id
        self.name = name
        self.quantity = quantity
    }
}
