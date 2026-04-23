import SwiftUI

struct KnownItemPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let title: String
    let onSelect: (KnownInventoryItem) -> Void
    let onAddNew: () -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if !historyItems.isEmpty {
                    Section {
                        ForEach(historyItems) { item in
                            itemRow(item, subtitle: historySubtitle(item))
                        }
                    } header: {
                        Text("Recent")
                    }
                }

                if !catalogResults.isEmpty {
                    Section {
                        ForEach(catalogResults) { item in
                            itemRow(item.asKnownItem(), subtitle: item.category.displayName)
                        }
                    } header: {
                        Text(searchText.isEmpty ? "Common Items" : "Catalog")
                    }
                }

                if historyItems.isEmpty && catalogResults.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search, or add a new item.")
                    )
                    .listRowBackground(Color.clear)
                }

                Section {
                    Button {
                        dismiss()
                        onAddNew()
                    } label: {
                        Label("Add new item", systemImage: "plus.circle")
                            .foregroundStyle(.tint)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search items")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: KnownInventoryItem, subtitle: String) -> some View {
        Button {
            AppLogger.action(
                "item_picker_selected",
                screen: title,
                metadata: ["item": item.name]
            )
            onSelect(item)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !item.lastQuantityText.isEmpty {
                    Text(item.lastQuantityText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var historyItems: [KnownInventoryItem] {
        knownItemStore.suggestions(matching: searchText)
    }

    private var catalogResults: [CatalogItem] {
        let historyNames = Set(historyItems.map { KnownInventoryItemNormalizer.normalize($0.name) })
        return PantryItemCatalog.items(matching: searchText)
            .filter { !historyNames.contains(KnownInventoryItemNormalizer.normalize($0.name)) }
            .prefix(searchText.isEmpty ? 30 : 50)
            .map { $0 }
    }

    private func historySubtitle(_ item: KnownInventoryItem) -> String {
        let parts: [String] = [
            item.defaultCategory.displayName,
            item.usageCount > 1 ? "Used \(item.usageCount)×" : nil
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }
}
