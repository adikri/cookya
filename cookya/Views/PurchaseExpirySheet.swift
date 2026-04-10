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

struct PantryBatchExpiryReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let items: [PantryItem]
    let onConfirm: (PantryItem, Date?) -> Void

    @State private var currentIndex = 0
    @State private var selectedOption: PantryExpiryOption = .tomorrow
    @State private var customDate: Date = .now

    private var currentItem: PantryItem {
        items[currentIndex]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("\(currentIndex + 1) of \(items.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currentItem.name)
                        .font(.headline)
                    Text(currentItem.quantityText.isEmpty ? currentItem.category.displayName : "\(currentItem.quantityText) • \(currentItem.category.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let expiryDate = currentItem.expiryDate {
                        Text("Current expiry: \(expiryDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(currentItem.isExpired ? .red : .orange)
                    }
                } header: {
                    Text(currentItem.isExpired ? "Expired Item" : "Use Soon Item")
                }

                Section {
                    ForEach(PantryExpiryOption.allCases) { option in
                        Button {
                            selectedOption = option
                            AppLogger.action(
                                "pantry_batch_expiry_option_selected",
                                screen: "PantryBatchExpiryReview",
                                metadata: ["item": currentItem.name, "option": option.rawValue]
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
                    Text("Update Expiry")
                } footer: {
                    Text("Review items quickly and move through the queue without reopening each pantry row.")
                }
            }
            .navigationTitle("Review Dates")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                AppLogger.screen("PantryBatchExpiryReview", metadata: ["count": String(items.count)])
                syncSelectionWithCurrentItem()
            }
            .onChange(of: currentIndex) { _, _ in
                syncSelectionWithCurrentItem()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Skip") {
                        advance()
                    }

                    Button(currentIndex == items.count - 1 ? "Save" : "Save & Next") {
                        let expiryDate = resolvedExpiryDate()
                        AppLogger.action(
                            "pantry_batch_expiry_confirmed",
                            screen: "PantryBatchExpiryReview",
                            metadata: [
                                "item": currentItem.name,
                                "option": selectedOption.rawValue,
                                "expirySet": expiryDate == nil ? "false" : "true"
                            ]
                        )
                        onConfirm(currentItem, expiryDate)
                        advance()
                    }
                }
            }
        }
    }

    private func advance() {
        if currentIndex == items.count - 1 {
            dismiss()
        } else {
            currentIndex += 1
        }
    }

    private func syncSelectionWithCurrentItem() {
        if let expiryDate = currentItem.expiryDate {
            customDate = expiryDate
        } else {
            customDate = .now
        }
        selectedOption = currentItem.isExpired ? .tomorrow : .custom
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

struct PurchaseExpirySheet_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseExpirySheet(
            item: GroceryItem(name: "Milk", quantityText: "1 L", category: .dairy),
            onConfirm: { _, _, _ in }
        )
    }
}
