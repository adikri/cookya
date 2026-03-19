import SwiftUI

private enum PurchaseExpiryOption: String, CaseIterable, Identifiable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case threeDays = "3 days"
    case oneWeek = "1 week"
    case custom = "Custom"
    case skip = "Skip"

    var id: String { rawValue }
}

private enum PantryExpiryOption: String, CaseIterable, Identifiable {
    case today = "Today"
    case tomorrow = "Tomorrow"
    case threeDays = "3 days"
    case oneWeek = "1 week"
    case custom = "Custom"
    case remove = "Remove expiry"

    var id: String { rawValue }
}

struct PurchaseExpirySheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: GroceryItem
    let onConfirm: (String, InventoryCategory, Date?) -> Void

    @State private var selectedOption: PurchaseExpiryOption = .today
    @State private var customDate: Date = .now
    @State private var quantityText: String
    @State private var category: InventoryCategory

    init(item: GroceryItem, onConfirm: @escaping (String, InventoryCategory, Date?) -> Void) {
        self.item = item
        self.onConfirm = onConfirm
        _quantityText = State(initialValue: item.quantityText)
        _category = State(initialValue: item.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.name)
                        .font(.headline)
                    Text("Confirm what should go into Pantry.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Add to Pantry")
                }

                Section {
                    QuantityInputView(title: "Quantity", quantityText: $quantityText)
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                } header: {
                    Text("Pantry Details")
                }

                Section {
                    ForEach(PurchaseExpiryOption.allCases) { option in
                        Button {
                            selectedOption = option
                            AppLogger.action(
                                "purchase_expiry_option_selected",
                                screen: "PurchaseExpirySheet",
                                metadata: ["item": item.name, "option": option.rawValue]
                            )
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                Spacer()
                                if selectedOption == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }

                    if selectedOption == .custom {
                        DatePicker("Expiry Date", selection: $customDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Expiry")
                }
            }
            .navigationTitle("Purchased")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AppLogger.screen("PurchaseExpirySheet", metadata: ["item": item.name])
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to Pantry") {
                        let expiryDate = resolvedExpiryDate()
                        AppLogger.action(
                            "purchase_expiry_confirmed",
                            screen: "PurchaseExpirySheet",
                            metadata: [
                                "item": item.name,
                                "quantity": quantityText.trimmingCharacters(in: .whitespacesAndNewlines),
                                "category": category.rawValue,
                                "option": selectedOption.rawValue,
                                "expirySet": expiryDate == nil ? "false" : "true"
                            ]
                        )
                        onConfirm(
                            quantityText.trimmingCharacters(in: .whitespacesAndNewlines),
                            category,
                            expiryDate
                        )
                        dismiss()
                    }
                }
            }
        }
    }

    private func resolvedExpiryDate() -> Date? {
        let calendar = Calendar.current
        switch selectedOption {
        case .today:
            return calendar.startOfDay(for: .now)
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))
        case .threeDays:
            return calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: .now))
        case .oneWeek:
            return calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: .now))
        case .custom:
            return calendar.startOfDay(for: customDate)
        case .skip:
            return nil
        }
    }
}

struct PantryExpirySheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: PantryItem
    let onConfirm: (Date?) -> Void

    @State private var selectedOption: PantryExpiryOption = .tomorrow
    @State private var customDate: Date

    init(item: PantryItem, onConfirm: @escaping (Date?) -> Void) {
        self.item = item
        self.onConfirm = onConfirm
        _customDate = State(initialValue: item.expiryDate ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Review Pantry Item") {
                    Text(item.name)
                        .font(.headline)
                    Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Update Expiry") {
                    ForEach(PantryExpiryOption.allCases) { option in
                        Button {
                            selectedOption = option
                            AppLogger.action(
                                "pantry_expiry_option_selected",
                                screen: "PantryExpirySheet",
                                metadata: ["item": item.name, "option": option.rawValue]
                            )
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                Spacer()
                                if selectedOption == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }

                    if selectedOption == .custom {
                        DatePicker("Expiry Date", selection: $customDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Update Expiry")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AppLogger.screen("PantryExpirySheet", metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"])
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let expiryDate = resolvedExpiryDate()
                        AppLogger.action(
                            "pantry_expiry_confirmed",
                            screen: "PantryExpirySheet",
                            metadata: [
                                "item": item.name,
                                "option": selectedOption.rawValue,
                                "expirySet": expiryDate == nil ? "false" : "true"
                            ]
                        )
                        onConfirm(expiryDate)
                        dismiss()
                    }
                }
            }
        }
    }

    private func resolvedExpiryDate() -> Date? {
        let calendar = Calendar.current
        switch selectedOption {
        case .today:
            return calendar.startOfDay(for: .now)
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))
        case .threeDays:
            return calendar.date(byAdding: .day, value: 3, to: calendar.startOfDay(for: .now))
        case .oneWeek:
            return calendar.date(byAdding: .day, value: 7, to: calendar.startOfDay(for: .now))
        case .custom:
            return calendar.startOfDay(for: customDate)
        case .remove:
            return nil
        }
    }
}

#Preview {
    PurchaseExpirySheet(
        item: GroceryItem(name: "Milk", quantityText: "1 L", category: .dairy),
        onConfirm: { _, _, _ in }
    )
}
