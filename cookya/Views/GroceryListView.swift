import SwiftUI

struct GroceryListView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore

    @State private var editorItem: GroceryItem?
    @State private var isAddingItem = false
    @State private var purchaseItem: GroceryItem?

    var body: some View {
        List {
            if inventoryStore.sortedGroceryItems.isEmpty {
                ContentUnavailableView(
                    "No Grocery Items",
                    systemImage: "cart",
                    description: Text("Add groceries you need, then mark them purchased to move them into the pantry.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(inventoryStore.sortedGroceryItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let note = item.note, !note.isEmpty {
                                    Text(note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button("Purchased") {
                                AppLogger.action("purchase_tapped", screen: "GroceryList", metadata: ["item": item.name])
                                purchaseItem = item
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editorItem = item
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await inventoryStore.deleteGroceryItem(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Grocery List")
        .onAppear {
            AppLogger.screen("GroceryList", metadata: ["itemCount": String(inventoryStore.groceryItems.count)])
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingItem = true
                } label: {
                    Label("Add Grocery Item", systemImage: "plus")
                }
            }
        }
        .refreshable {
            await inventoryStore.refresh()
        }
        .sheet(isPresented: $isAddingItem) {
            GroceryItemEditorView(item: nil) { item in
                Task { await inventoryStore.saveGroceryItem(item) }
            }
        }
        .sheet(item: $editorItem) { item in
            GroceryItemEditorView(item: item) { updated in
                Task { await inventoryStore.saveGroceryItem(updated) }
            }
        }
        .sheet(item: $purchaseItem) { item in
            PurchaseExpirySheet(item: item) { expiryDate in
                Task { await inventoryStore.markPurchased(item, expiryDate: expiryDate) }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GroceryListView()
            .environmentObject(InventoryStore())
    }
}
