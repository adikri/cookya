import SwiftUI

struct PantryView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore

    @State private var editorItem: PantryItem?
    @State private var expiryItem: PantryItem?
    @State private var isAddingItem = false

    var body: some View {
        List {
            if inventoryStore.sortedPantryItems.isEmpty {
                ContentUnavailableView(
                    "No Pantry Items",
                    systemImage: "cabinet",
                    description: Text("Add ingredients you already have at home so Cookya can suggest realistic meals.")
                )
                .listRowBackground(Color.clear)
            } else {
                if !useSoonPantryItems.isEmpty {
                    Section {
                        ForEach(useSoonPantryItems) { item in
                            pantryRow(for: item)
                        }
                    } header: {
                        Text("Use Soon")
                    } footer: {
                        Text("These items are still usable, but they should be reviewed soon to avoid waste.")
                    }
                }

                if !activePantryItems.isEmpty {
                    Section("Available") {
                        ForEach(activePantryItems) { item in
                            pantryRow(for: item)
                        }
                    }
                }

                if !expiredPantryItems.isEmpty {
                    Section {
                        ForEach(expiredPantryItems) { item in
                            pantryRow(for: item)
                        }
                    } header: {
                        Text("Expired")
                    } footer: {
                        Text("Expired items stay visible so you can update expiry, discard them, or review what should no longer be used.")
                    }
                }
            }
        }
        .navigationTitle("Pantry")
        .onAppear {
            AppLogger.screen("Pantry", metadata: ["itemCount": String(inventoryStore.pantryItems.count)])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingItem = true
                } label: {
                    Label("Add Pantry Item", systemImage: "plus")
                }
            }
        }
        .refreshable {
            await inventoryStore.refresh()
        }
        .sheet(isPresented: $isAddingItem) {
            PantryItemEditorView(item: nil) { item in
                Task { await inventoryStore.savePantryItem(item) }
            }
        }
        .sheet(item: $editorItem) { item in
            PantryItemEditorView(item: item) { updated in
                Task { await inventoryStore.savePantryItem(updated) }
            }
        }
        .sheet(item: $expiryItem) { item in
            PantryExpirySheet(item: item) { expiryDate in
                var updated = item
                updated.expiryDate = expiryDate
                updated.updatedAt = .now
                Task { await inventoryStore.savePantryItem(updated) }
            }
        }
    }

    private var activePantryItems: [PantryItem] {
        inventoryStore.sortedPantryItems.filter { !$0.isExpired && !$0.isExpiringSoon }
    }

    private var useSoonPantryItems: [PantryItem] {
        inventoryStore.sortedPantryItems.filter(\.isExpiringSoon)
    }

    private var expiredPantryItems: [PantryItem] {
        inventoryStore.sortedPantryItems.filter(\.isExpired)
    }

    @ViewBuilder
    private func pantryRow(for item: PantryItem) -> some View {
        Button {
            AppLogger.action("pantry_row_opened", screen: "Pantry", metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"])
            editorItem = item
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if item.isExpiringSoon {
                            Text("Use soon")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.14), in: Capsule())
                                .foregroundStyle(.orange)
                        }
                        if item.isExpired {
                            Text("Expired")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.14), in: Capsule())
                                .foregroundStyle(.red)
                        }
                    }

                    Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let expiryDate = item.expiryDate {
                    Text(expiryDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(item.isExpired ? .red : (item.isExpiringSoon ? .orange : .secondary))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                AppLogger.action(
                    "pantry_expiry_action_tapped",
                    screen: "Pantry",
                    metadata: ["item": item.name, "action": "update_expiry"]
                )
                expiryItem = item
            } label: {
                Label("Update Expiry", systemImage: "calendar.badge.clock")
            }
            .tint(.orange)
        }
        .swipeActions {
            Button(role: .destructive) {
                AppLogger.action(
                    "expired_item_discarded",
                    screen: "Pantry",
                    metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"]
                )
                Task { await inventoryStore.deletePantryItem(item) }
            } label: {
                Label(item.isExpired ? "Discard" : "Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button {
                AppLogger.action(
                    "pantry_expiry_action_tapped",
                    screen: "Pantry",
                    metadata: ["item": item.name, "action": "update_expiry"]
                )
                expiryItem = item
            } label: {
                Label("Update Expiry", systemImage: "calendar")
            }

            Button(role: .destructive) {
                AppLogger.action(
                    "expired_item_discarded",
                    screen: "Pantry",
                    metadata: ["item": item.name, "expired": item.isExpired ? "true" : "false"]
                )
                Task { await inventoryStore.deletePantryItem(item) }
            } label: {
                Label(item.isExpired ? "Discard" : "Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PantryView()
            .environmentObject(InventoryStore())
    }
}
