import SwiftUI

struct PantryItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let item: PantryItem?
    var prefill: KnownInventoryItem? = nil
    let onSave: (PantryItem) -> Void

    @State private var name = ""
    @State private var quantityText = ""
    @State private var category: InventoryCategory = .pantry
    @State private var hasExpiryDate = false
    @State private var expiryDate = Date()
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

                Section("Expiry") {
                    Toggle("Track expiry", isOn: $hasExpiryDate)
                    if hasExpiryDate {
                        DatePicker("Expiry date", selection: $expiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Pantry Item" : "Edit Pantry Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmedName.isEmpty else { return }
                        let pantryItem = PantryItem(
                            id: item?.id ?? UUID(),
                            name: trimmedName,
                            quantityText: quantityText.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category,
                            expiryDate: hasExpiryDate ? expiryDate : nil,
                            updatedAt: .now
                        )
                        onSave(pantryItem)
                        knownItemStore.upsertFromPantryItem(pantryItem)
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
            hasExpiryDate = item.expiryDate != nil
            expiryDate = item.expiryDate ?? Date()
        } else if let prefill {
            name = prefill.name
            quantityText = prefill.lastQuantityText
            category = prefill.defaultCategory
        }
    }
}
