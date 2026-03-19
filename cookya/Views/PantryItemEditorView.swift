import SwiftUI

struct PantryItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let item: PantryItem?
    let onSave: (PantryItem) -> Void

    @State private var name = ""
    @State private var quantityText = ""
    @State private var category: InventoryCategory = .pantry
    @State private var hasExpiryDate = false
    @State private var expiryDate = Date()
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

                Section("Expiry") {
                    Toggle("Track expiry", isOn: $hasExpiryDate)
                    if hasExpiryDate {
                        DatePicker("Expiry date", selection: $expiryDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Pantry Item" : "Edit Pantry Item")
            .sheet(isPresented: $isShowingKnownItemPicker) {
                KnownItemPickerView(title: "Choose Pantry Item") { suggestion in
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
        guard let item else { return }
        name = item.name
        quantityText = item.quantityText
        category = item.category
        hasExpiryDate = item.expiryDate != nil
        expiryDate = item.expiryDate ?? Date()
    }

    private func applySuggestion(_ suggestion: KnownInventoryItem) {
        name = suggestion.name
        quantityText = suggestion.lastQuantityText
        category = suggestion.defaultCategory
        AppLogger.action("known_item_selected", screen: "PantryEditor", metadata: ["item": suggestion.name, "source": suggestion.lastSource.rawValue])
    }
}
