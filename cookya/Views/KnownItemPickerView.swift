import SwiftUI

struct KnownItemPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var knownItemStore: KnownItemStore

    let title: String
    let onSelect: (KnownInventoryItem) -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "No remembered items",
                        systemImage: "tray",
                        description: Text(searchText.isEmpty ? "Once you save Pantry or Grocery items, they’ll appear here for quick reuse." : "No remembered items match your search.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredItems) { item in
                        Button {
                            AppLogger.action(
                                "known_item_picker_selected",
                                screen: title,
                                metadata: [
                                    "item": item.name,
                                    "source": item.lastSource.rawValue
                                ]
                            )
                            onSelect(item)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .foregroundStyle(.primary)
                                    Text(itemSubtitle(item))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search remembered items")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filteredItems: [KnownInventoryItem] {
        knownItemStore.suggestions(matching: searchText)
    }

    private func itemSubtitle(_ item: KnownInventoryItem) -> String {
        let detail = item.lastQuantityText.isEmpty
            ? item.defaultCategory.displayName
            : "\(item.lastQuantityText) • \(item.defaultCategory.displayName)"
        return "Last used in \(item.lastSource.rawValue.capitalized) • \(detail)"
    }
}
