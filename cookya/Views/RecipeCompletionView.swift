import SwiftUI

struct RecipeCompletionView: View {
    @Environment(\.dismiss) private var dismiss

    let pantrySelections: [PantryRecipeSelection]
    let onConfirm: ([PantryConsumption]) -> Void

    @State private var consumptions: [PantryConsumption] = []
    @State private var validationErrors: [UUID: String] = [:]
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Tell Cookya what you actually used. Enter only the amounts you want removed from pantry. Leave a field blank to keep that item unchanged.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                ForEach($consumptions) { $consumption in
                    Section(consumption.pantryItemName) {
                        if !consumption.currentQuantityText.isEmpty {
                            Text("Current pantry quantity: \(consumption.currentQuantityText)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        QuantityInputView(
                            title: "Amount used",
                            quantityText: $consumption.usedQuantityText
                        )

                        if let error = validationErrors[consumption.id] {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .onChange(of: consumption.usedQuantityText) { _, _ in
                        validationErrors[consumption.id] = nil
                        if validationErrors.isEmpty {
                            validationMessage = nil
                        }
                    }
                }
            }
            .navigationTitle("Cooked This")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        let errors = validateConsumptions()
                        guard errors.isEmpty else {
                            validationErrors = errors
                            validationMessage = "Cookya could not safely update pantry for one or more items. Update the quantities below or fix the pantry entry before confirming."
                            return
                        }

                        validationErrors = [:]
                        validationMessage = nil
                        onConfirm(consumptions)
                        dismiss()
                    }
                }
            }
            .onAppear {
                consumptions = pantrySelections.map {
                    PantryConsumption(item: $0.pantryItem, usedQuantityText: $0.selectedQuantityText)
                }
            }
        }
    }

    private func validateConsumptions() -> [UUID: String] {
        var errors: [UUID: String] = [:]

        for consumption in consumptions {
            guard let pantryItem = pantrySelections.first(where: { $0.pantryItem.id == consumption.pantryItemId })?.pantryItem else {
                continue
            }

            switch pantryItem.applyingConsumption(consumption.usedQuantityText) {
            case .warning(let message):
                errors[consumption.id] = message
            case .unchanged, .updated, .remove:
                break
            }
        }

        return errors
    }
}
