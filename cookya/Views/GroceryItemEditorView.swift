import SwiftUI

struct GroceryItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let item: GroceryItem?
    let onSave: (GroceryItem) -> Void

    @State private var name = ""
    @State private var quantityText = ""
    @State private var category: InventoryCategory = .pantry
    @State private var note = ""
    @State private var isShowingKnownItemPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name", text: $name)
                    if item == nil && !knownItemStore.recentItems.isEmpty {
                        Button {
                            isShowingKnownItemPicker = true
                        } label: {
                            HStack {
                                Label("Choose from memory", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
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
            .sheet(isPresented: $isShowingKnownItemPicker) {
                KnownItemPickerView(title: "Choose Grocery Item") { suggestion in
                    applySuggestion(suggestion)
                }
            }
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
        guard let item else { return }
        name = item.name
        quantityText = item.quantityText
        category = item.category
        note = item.note ?? ""
    }

    private func applySuggestion(_ suggestion: KnownInventoryItem) {
        name = suggestion.name
        quantityText = suggestion.lastQuantityText
        category = suggestion.defaultCategory
        AppLogger.action("known_item_selected", screen: "GroceryEditor", metadata: ["item": suggestion.name, "source": suggestion.lastSource.rawValue])
    }
}
