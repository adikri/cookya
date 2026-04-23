import SwiftUI

struct GroceryItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let item: GroceryItem?
    var prefill: KnownInventoryItem? = nil
    let onSave: (GroceryItem) -> Void

    @State private var name = ""
    @State private var quantityText = ""
    @State private var category: InventoryCategory = .pantry
    @State private var note = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    QuantityInputView(title: "Quantity", quantityText: $quantityText)
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional note", text: $note, axis: .vertical)
                }
            }
            .navigationTitle(item == nil ? "Add Grocery Item" : "Edit Grocery Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        let groceryItem = GroceryItem(
                            id: item?.id ?? UUID(),
                            name: trimmedName,
                            quantityText: quantityText.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
                            source: item?.source ?? .manual,
                            reasonRecipes: item?.reasonRecipes ?? [],
                            createdAt: item?.createdAt ?? .now
                        )
                        onSave(groceryItem)
                        knownItemStore.upsertFromGroceryItem(groceryItem)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let item {
            name = item.name
            quantityText = item.quantityText
            category = item.category
            note = item.note ?? ""
        } else if let prefill {
            name = prefill.name
            quantityText = prefill.lastQuantityText
            category = prefill.defaultCategory
        }
    }
}
