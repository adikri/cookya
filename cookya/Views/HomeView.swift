import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What's cooking \(profileStore.activeProfile?.name ?? "Guest")?!")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let syncError = inventoryStore.lastSyncError {
                        Label(syncError, systemImage: "wifi.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }

                    cardSection("Let's Cook", subtitle: cookNowSubtitle) {
                        VStack(alignment: .leading, spacing: 14) {
                            NavigationLink {
                                IngredientInputView()
                            } label: {
                                dashboardButtonLabel(
                                    title: "Cook from pantry",
                                    subtitle: "Select pantry items and add extras if needed",
                                    systemImage: "fork.knife"
                                )
                            }

                            if let latestCookedRecord {
                                Divider()
                                Text("Recently cooked")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                NavigationLink {
                                    CookAgainView(record: latestCookedRecord)
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(latestCookedRecord.recipeTitle)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(latestCookedRecord.cookedAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(recentCookedStatus(for: latestCookedRecord))
                                            .font(.caption)
                                            .foregroundStyle(recentCookedCanBeCookedAgain(latestCookedRecord) ? .green : .orange)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }

                    if !inventoryStore.expiredPantryItems.isEmpty {
                        cardSection(
                            "Expired Review",
                            subtitle: "\(inventoryStore.expiredPantryItems.count) item(s) need attention in Pantry"
                        ) {
                            NavigationLink {
                                PantryView()
                            } label: {
                                dashboardButtonLabel(
                                    title: "Review expired items",
                                    subtitle: "Discard them or update expiry before they affect your kitchen decisions",
                                    systemImage: "exclamationmark.triangle"
                                )
                            }
                        }
                    }

                    cardSection("Expiring Soon", subtitle: expiringSoonSubtitle) {
                        if inventoryStore.expiringSoonItems.isEmpty {
                            Text("Nothing needs urgent use right now. Add expiry dates to pantry items to see smarter suggestions.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(inventoryStore.expiringSoonItems.prefix(3))) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .fontWeight(.semibold)
                                            Text(item.quantityText.isEmpty ? item.category.displayName : "\(item.quantityText) • \(item.category.displayName)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(expiryLabel(for: item))
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }

                    HStack(alignment: .top, spacing: 16) {
                        cardSection("Pantry", subtitle: "\(inventoryStore.pantryItems.count) items available") {
                            NavigationLink {
                                PantryView()
                            } label: {
                                dashboardButtonLabel(
                                    title: "Manage pantry",
                                    subtitle: "Add, edit, and remove ingredients at home",
                                    systemImage: "cabinet"
                                )
                            }
                        }

                        cardSection("Grocery", subtitle: "\(inventoryStore.groceryItems.count) items on your list") {
                            NavigationLink {
                                GroceryListView()
                            } label: {
                                dashboardButtonLabel(
                                    title: "Open grocery list",
                                    subtitle: "Track what to buy and mark items purchased",
                                    systemImage: "cart"
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                AppLogger.screen("Home", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
                await inventoryStore.refreshIfNeeded()
            }
            .refreshable {
                await inventoryStore.refresh()
            }
        }
    }

    private var cookNowSubtitle: String {
        if inventoryStore.pantryItems.isEmpty {
            return "Build your pantry first, then generate recipes around what you already have."
        }
        if !inventoryStore.expiredPantryItems.isEmpty {
            return "\(inventoryStore.expiredPantryItems.count) item(s) already expired and need review in Pantry."
        }
        if !inventoryStore.expiringSoonItems.isEmpty {
            return "You have \(inventoryStore.expiringSoonItems.count) item(s) expiring soon."
        }
        return "Use your pantry as the base and type extra ingredients only when needed."
    }

    private var expiringSoonSubtitle: String? {
        guard !inventoryStore.expiringSoonItems.isEmpty else { return nil }
        return "Use these ingredients before they go to waste"
    }

    private func dashboardButtonLabel(title: String, subtitle: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func cardSection<Content: View>(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func expiryLabel(for item: PantryItem) -> String {
        guard let days = item.daysUntilExpiry(referenceDate: .now) else {
            return "No expiry"
        }
        switch days {
        case ..<0:
            return "Expired"
        case 0:
            return "Today"
        case 1:
            return "1 day"
        default:
            return "\(days) days"
        }
    }

    private var latestCookedRecord: CookedMealRecord? {
        cookedMealStore.records(for: profileStore.activeProfile).first
    }

    private func recentCookedCanBeCookedAgain(_ record: CookedMealRecord) -> Bool {
        replayIssues(for: record).isEmpty
    }

    private func recentCookedStatus(for record: CookedMealRecord) -> String {
        let issues = replayIssues(for: record)
        if issues.isEmpty {
            return "Everything needed is available in pantry."
        }
        return issues.first ?? "Some ingredients are not ready in pantry."
    }

    private func replayIssues(for record: CookedMealRecord) -> [String] {
        inventoryStore.availabilityIssues(for: record.consumptions)
    }
}

private struct CookAgainView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore

    let record: CookedMealRecord

    @State private var isShowingCompletionSheet = false
    @State private var completionMessage: String?

    var body: some View {
        List {
            Section("Recipe") {
                Text(record.recipeTitle)
                    .font(.headline)
                Text("Last cooked on \(record.cookedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Ingredients used last time") {
                if record.consumptions.isEmpty {
                    Text("No pantry usage was recorded for this meal.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(record.consumptions) { consumption in
                        Text("\(consumption.pantryItemName): \(consumption.usedQuantityText)")
                    }
                }
            }

            if replayChecks.isEmpty {
                Section("Availability") {
                    Text("Cookya needs pantry usage data from a previous cook to check availability here.")
                        .foregroundStyle(.secondary)
                }
            } else if replayIssues.isEmpty {
                Section("Availability") {
                    Label("Everything needed is available in pantry.", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Section {
                    Button("Cook Again") {
                        AppLogger.action(
                            "recent_cooked_selected",
                            screen: "CookAgain",
                            metadata: ["recipeTitle": record.recipeTitle, "result": "available"]
                        )
                        isShowingCompletionSheet = true
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Section("Availability") {
                    ForEach(replayIssues, id: \.self) { issue in
                        Text(issue)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section("Recipe ingredients") {
                ForEach(record.recipeIngredients) { ingredient in
                    Text(ingredient.quantity.isEmpty ? ingredient.name : "\(ingredient.name) (\(ingredient.quantity))")
                }
            }
        }
        .navigationTitle("Cook Again")
        .onAppear {
            AppLogger.screen("CookAgain", metadata: ["recipeTitle": record.recipeTitle])
        }
        .sheet(isPresented: $isShowingCompletionSheet) {
            RecipeCompletionView(pantrySelections: replaySelections) { consumptions in
                Task {
                    let result = await inventoryStore.consumePantryItems(consumptions)
                    let warnings = result.warnings
                    guard result.applied else {
                        completionMessage = warnings.joined(separator: "\n")
                        AppLogger.action(
                            "recent_cooked_marked_again_blocked",
                            screen: "CookAgain",
                            metadata: [
                                "recipeTitle": record.recipeTitle,
                                "warningCount": String(warnings.count)
                            ]
                        )
                        return
                    }
                    cookedMealStore.addReplayRecord(
                        from: record,
                        consumptions: consumptions,
                        warnings: warnings,
                        profile: profileStore.activeProfile
                    )
                    AppLogger.action(
                        "recent_cooked_marked_again",
                        screen: "CookAgain",
                        metadata: [
                            "recipeTitle": record.recipeTitle,
                            "warningCount": String(warnings.count)
                        ]
                    )
                    if warnings.isEmpty {
                        completionMessage = "Pantry updated from what you cooked."
                    } else {
                        completionMessage = warnings.joined(separator: "\n")
                    }
                }
            }
        }
        .alert("Cooking Update", isPresented: Binding(
            get: { completionMessage != nil },
            set: { if !$0 { completionMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(completionMessage ?? "")
        }
    }

    private var replayChecks: [PantryAvailabilityCheck] {
        inventoryStore.availabilityChecks(for: record.consumptions)
    }

    private var replayIssues: [String] {
        replayChecks.compactMap(\.issue)
    }

    private var replaySelections: [PantryRecipeSelection] {
        inventoryStore.replaySelections(for: record.consumptions)
    }
}

#Preview {
    HomeView()
        .environmentObject(InventoryStore())
        .environmentObject(ProfileStore())
        .environmentObject(CookedMealStore())
}
