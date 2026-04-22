import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var inventoryStore: InventoryStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var cookedMealStore: CookedMealStore
    @EnvironmentObject private var recipeStore: RecipeStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("What's cooking \(profileStore.activeProfile?.name ?? "Guest")?!")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let goals = profileStore.activeProfile?.effectiveNutritionGoals {
                        let today = cookedMealStore.todayNutrition(for: profileStore.activeProfile)
                        nutritionProgressCard(today: today, goals: goals)
                    }

                    if let syncError = inventoryStore.lastSyncError {
                        Label(syncError, systemImage: "wifi.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }

                    if let bestNextStep {
                        sectionHeading("Best Next Step", subtitle: "Cookya picked the most useful action for your kitchen right now.")

                        bestNextStepCard(bestNextStep)
                    }

                    heroCookCard

                    if hasAttentionItems {
                        sectionHeading("Attention Needed", subtitle: "Take care of the kitchen items that need action first.")

                        if !inventoryStore.expiredPantryItems.isEmpty {
                            NavigationLink {
                                PantryView()
                            } label: {
                                actionCard(
                                    title: "Expired Review",
                                    subtitle: "\(inventoryStore.expiredPantryItems.count) item(s) need review in Pantry",
                                    systemImage: "exclamationmark.triangle",
                                    tint: .red
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        if !inventoryStore.expiringSoonItems.isEmpty {
                            NavigationLink {
                                PantryView()
                            } label: {
                                actionCard(
                                    title: "Use Soon",
                                    subtitle: expiringSoonSummary,
                                    systemImage: "clock.badge.exclamationmark",
                                    tint: .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    sectionHeading("Cook Faster", subtitle: "Jump back into meals that already fit your kitchen.")

                    VStack(spacing: 12) {
                        if let latestCookedRecord {
                            NavigationLink {
                                CookAgainView(record: latestCookedRecord)
                            } label: {
                                actionCard(
                                    title: "Cook Again",
                                    subtitle: "\(latestCookedRecord.recipeTitle)\n\(recentCookedStatus(for: latestCookedRecord))",
                                    systemImage: "arrow.clockwise.heart",
                                    tint: recentCookedCanBeCookedAgain(latestCookedRecord) ? .green : .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            SavedRecipesView()
                        } label: {
                            actionCard(
                                title: "Saved Recipes",
                                subtitle: savedRecipesSubtitle,
                                systemImage: "bookmark",
                                tint: .blue
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    sectionHeading("Kitchen Management", subtitle: "Keep pantry and grocery up to date without losing focus on cooking.")

                    HStack(alignment: .top, spacing: 16) {
                        NavigationLink {
                            PantryView()
                        } label: {
                            managementCard(
                                title: "Pantry",
                                subtitle: pantrySummary,
                                detail: "Manage ingredients at home",
                                systemImage: "cabinet"
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            GroceryListView()
                        } label: {
                            managementCard(
                                title: "Grocery",
                                subtitle: grocerySummary,
                                detail: "Track what to buy next",
                                systemImage: "cart"
                            )
                        }
                        .buttonStyle(.plain)
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

    private var heroCookCard: some View {
        cardSection("Let's Cook", subtitle: cookNowSubtitle) {
            VStack(alignment: .leading, spacing: 14) {
                NavigationLink {
                    IngredientInputView()
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Cook from pantry", systemImage: "fork.knife")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Select what you already have and let Cookya build tonight's meal around it.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.tint)
                        }

                        flowLayout(statusChips)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.12), Color.accentColor.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }
                .buttonStyle(.plain)
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

    private var savedRecipesSubtitle: String {
        let count = recipeStore.recipes(for: profileStore.activeProfile).count
        if count == 0 {
            return "No saved recipes yet. Save a recipe once you find one worth repeating."
        }
        if count == 1 {
            return "1 saved recipe ready to revisit"
        }
        return "\(count) saved recipes ready to revisit"
    }

    private var pantrySummary: String {
        if inventoryStore.pantryItems.isEmpty {
            return "No items yet"
        }
        return "\(inventoryStore.pantryItems.count) items available"
    }

    private var grocerySummary: String {
        if inventoryStore.groceryItems.isEmpty {
            return "Nothing on your list"
        }
        return "\(inventoryStore.groceryItems.count) items on your list"
    }

    private var expiringSoonSummary: String {
        let names = inventoryStore.expiringSoonItems.prefix(2).map(\.name).joined(separator: ", ")
        if inventoryStore.expiringSoonItems.count <= 2 {
            return names
        }
        return "\(names), and \(inventoryStore.expiringSoonItems.count - 2) more"
    }

    private var hasAttentionItems: Bool {
        !inventoryStore.expiredPantryItems.isEmpty || !inventoryStore.expiringSoonItems.isEmpty
    }

    private var statusChips: [StatusChip] {
        var chips: [StatusChip] = []

        if !inventoryStore.expiringSoonItems.isEmpty {
            chips.append(StatusChip(
                text: "\(inventoryStore.expiringSoonItems.count) expiring soon",
                systemImage: "clock",
                tint: .orange
            ))
        }

        if !inventoryStore.expiredPantryItems.isEmpty {
            chips.append(StatusChip(
                text: "\(inventoryStore.expiredPantryItems.count) expired",
                systemImage: "exclamationmark.triangle",
                tint: .red
            ))
        }

        if let latestCookedRecord {
            chips.append(StatusChip(
                text: "Last cooked: \(latestCookedRecord.recipeTitle)",
                systemImage: "flame",
                tint: .green
            ))
        }

        if chips.isEmpty {
            chips.append(StatusChip(
                text: "Pantry is ready for a fresh recipe",
                systemImage: "sparkles",
                tint: .blue
            ))
        }

        return chips
    }

    private func nutritionProgressCard(today: NutritionSummary, goals: NutritionGoals) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Nutrition")
                .font(.headline)

            nutritionRow(
                label: "Calories",
                current: today.calories,
                goal: goals.dailyCalories,
                unit: "kcal",
                color: .orange
            )

            nutritionRow(
                label: "Protein",
                current: today.proteinG,
                goal: goals.dailyProteinG,
                unit: "g",
                color: .blue
            )
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func nutritionRow(label: String, current: Int, goal: Int, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(current) / \(goal)\(unit)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(current >= goal ? .green : .primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(current >= goal ? Color.green : color)
                        .frame(width: geo.size.width * min(1, goal > 0 ? CGFloat(current) / CGFloat(goal) : 0), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    private func sectionHeading(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func actionCard(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func managementCard(title: String, subtitle: String, detail: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func flowLayout(_ chips: [StatusChip]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chips) { chip in
                HStack(spacing: 8) {
                    Image(systemName: chip.systemImage)
                    Text(chip.text)
                        .lineLimit(1)
                }
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(chip.tint.opacity(0.12), in: Capsule())
                .foregroundStyle(chip.tint)
            }
        }
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

    private var savedRecipes: [SavedRecipe] {
        recipeStore.recipes(for: profileStore.activeProfile)
    }

    private var favoriteSavedRecipes: [SavedRecipe] {
        savedRecipes.filter(\.isFavorite)
    }

    private var recommendationEngine: HomeRecommendationEngine {
        HomeRecommendationEngine(
            expiredPantryItems: inventoryStore.expiredPantryItems,
            expiringSoonItems: inventoryStore.expiringSoonItems,
            usablePantryItems: inventoryStore.usablePantryItems,
            savedRecipes: savedRecipes,
            cookedRecords: cookedMealStore.records(for: profileStore.activeProfile),
            staples: cookedMealStore.staples(for: profileStore.activeProfile),
            nutritionGap: cookedMealStore.nutritionGap(for: profileStore.activeProfile),
            savedRecipeIssues: { saved in
                inventoryStore.availabilityIssues(for: saved.recipe.ingredients)
            },
            savedRecipeMissingCount: { saved in
                inventoryStore.availabilityChecks(for: saved.recipe.ingredients).filter(\.isMissing).count
            },
            replayIssues: { record in
                inventoryStore.availabilityIssues(for: record.consumptions)
            }
        )
    }

    private var bestNextStep: HomeRecommendation? {
        recommendationEngine.bestNextStep()
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

    @ViewBuilder
    private func bestNextStepCard(_ recommendation: HomeRecommendation) -> some View {
        switch recommendation {
        case .expiredReview(let count):
            NavigationLink {
                PantryView()
            } label: {
                actionCard(
                    title: "Review expired items",
                    subtitle: "\(count) pantry item(s) need review before they affect cooking decisions.",
                    systemImage: "exclamationmark.triangle",
                    tint: .red
                )
            }
            .buttonStyle(.plain)

        case .favoriteReady(let saved):
            NavigationLink {
                SavedRecipeDetailView(saved: saved)
            } label: {
                actionCard(
                    title: "Favorite ready: \(saved.recipe.title)",
                    subtitle: "One of your favorites can be cooked right now from what’s already in pantry.",
                    systemImage: "star.fill",
                    tint: .yellow
                )
            }
            .buttonStyle(.plain)

        case .stapleReady(let record):
            NavigationLink {
                CookAgainView(record: record)
            } label: {
                actionCard(
                    title: "Staple ready: \(record.recipeTitle)",
                    subtitle: "You’ve made this multiple times and everything needed is available again.",
                    systemImage: "flame.fill",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

        case .cookAgain(let record):
            NavigationLink {
                CookAgainView(record: record)
            } label: {
                actionCard(
                    title: "Cook again: \(record.recipeTitle)",
                    subtitle: "You made this recently and everything needed is available right now.",
                    systemImage: "arrow.clockwise.heart",
                    tint: .green
                )
            }
            .buttonStyle(.plain)

        case .tonightsPick(let saved, let reason):
            NavigationLink {
                SavedRecipeDetailView(saved: saved)
            } label: {
                actionCard(
                    title: "Tonight's pick: \(saved.recipe.title)",
                    subtitle: reason,
                    systemImage: "bolt.fill",
                    tint: .green
                )
            }
            .buttonStyle(.plain)

        case .savedRecipeReady(let saved):
            NavigationLink {
                SavedRecipeDetailView(saved: saved)
            } label: {
                actionCard(
                    title: "Saved recipe ready",
                    subtitle: "\(saved.recipe.title) can be cooked now from what you already have.",
                    systemImage: "bookmark.fill",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)

        case .savedRecipeNearMiss(let saved, let missingCount, let reason):
            NavigationLink {
                SavedRecipeDetailView(saved: saved)
            } label: {
                actionCard(
                    title: "You're close to \(saved.recipe.title)",
                    subtitle: "Missing \(missingCount) item(s). \(reason)",
                    systemImage: "cart.badge.plus",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

        case .useSoon(let items):
            NavigationLink {
                IngredientInputView()
            } label: {
                actionCard(
                    title: "Use expiring ingredients tonight",
                    subtitle: "Try cooking with \(items.map(\.name).joined(separator: ", ")) before they go to waste.",
                    systemImage: "clock.badge.exclamationmark",
                    tint: .orange
                )
            }
            .buttonStyle(.plain)

        case .cookFromPantry:
            NavigationLink {
                IngredientInputView()
            } label: {
                actionCard(
                    title: "Cook from pantry",
                    subtitle: "You already have ingredients at home. Let Cookya build a realistic meal around them.",
                    systemImage: "fork.knife",
                    tint: .accentColor
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct StatusChip: Identifiable {
    let id = UUID()
    let text: String
    let systemImage: String
    let tint: Color
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(InventoryStore())
            .environmentObject(ProfileStore())
            .environmentObject(CookedMealStore())
            .environmentObject(RecipeStore())
    }
}
