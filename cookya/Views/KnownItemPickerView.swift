import SwiftUI

struct KnownItemPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let title: String
    let onSelect: (KnownInventoryItem) -> Void
    let onAddNew: () -> Void

    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            Group {
                if !searchText.isEmpty {
                    searchResultsList
                } else if let category = selectedCategory {
                    categoryItemsList(category)
                } else {
                    browseView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search items")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if selectedCategory != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            selectedCategory = nil
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Browse (empty state)

    private var browseView: some View {
        List {
            if !historyItems.isEmpty {
                Section {
                    ForEach(historyItems.prefix(5)) { item in
                        itemRow(item, subtitle: historySubtitle(item))
                    }
                } header: {
                    Text("Recent")
                }
            }

            Section {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(InventoryCategory.allCases, id: \.self) { category in
                        categoryCard(category)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Browse by category")
            }

            Section {
                addNewRow
            }
        }
    }

    // MARK: - Category items

    private func categoryItemsList(_ category: InventoryCategory) -> some View {
        List {
            let items = PantryItemCatalog.items(in: category)
            let historyInCategory = historyItems.filter { $0.defaultCategory == category }

            if !historyInCategory.isEmpty {
                Section {
                    ForEach(historyInCategory) { item in
                        itemRow(item, subtitle: historySubtitle(item))
                    }
                } header: {
                    Text("Recent")
                }
            }

            if !items.isEmpty {
                Section {
                    ForEach(items) { item in
                        itemRow(item.asKnownItem(), subtitle: item.defaultQuantityText)
                    }
                } header: {
                    Text(category.displayName)
                }
            }

            Section { addNewRow }
        }
        .navigationTitle(category.displayName)
    }

    // MARK: - Search results

    private var searchResultsList: some View {
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
                    Text("Catalog")
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

            Section { addNewRow }
        }
    }

    // MARK: - Subviews

    private func categoryCard(_ category: InventoryCategory) -> some View {
        Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundStyle(.tint)
                Text(category.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func itemRow(_ item: KnownInventoryItem, subtitle: String) -> some View {
        Button {
            AppLogger.action("item_picker_selected", screen: title, metadata: ["item": item.name])
            onSelect(item)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).foregroundStyle(.primary)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if !item.lastQuantityText.isEmpty {
                    Text(item.lastQuantityText)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var addNewRow: some View {
        Button {
            dismiss()
            onAddNew()
        } label: {
            Label("Add new item", systemImage: "plus.circle")
                .foregroundStyle(.tint)
        }
    }

    // MARK: - Data

    private var historyItems: [KnownInventoryItem] {
        knownItemStore.suggestions(matching: searchText)
    }

    private var catalogResults: [CatalogItem] {
        let historyNames = Set(historyItems.map { KnownInventoryItemNormalizer.normalize($0.name) })
        return PantryItemCatalog.items(matching: searchText)
            .filter { !historyNames.contains(KnownInventoryItemNormalizer.normalize($0.name)) }
            .prefix(50).map { $0 }
    }

    private func historySubtitle(_ item: KnownInventoryItem) -> String {
        [item.defaultCategory.displayName,
         item.usageCount > 1 ? "Used \(item.usageCount)×" : nil]
            .compactMap { $0 }.joined(separator: " · ")
    }
}
