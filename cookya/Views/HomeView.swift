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

                    // Greeting
                    Text("What's cooking \(profileStore.activeProfile?.name ?? "there")?!")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Sync error (rare, keep compact)
                    if let syncError = inventoryStore.lastSyncError {
                        Label(syncError, systemImage: "wifi.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    }

                    // Tonight hero card — single dominant surface
                    tonightHeroCard

                    // Compact expiring-soon alert (only when not already shown in hero)
                    if showExpiringSoonBanner {
                        expiringSoonBanner
                    }
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                AppLogger.screen("Home", metadata: ["profile": profileStore.activeProfile?.name ?? "Guest"])
                if let recommendation = bestNextStep {
                    AppLogger.action(
                        "home_recommendation_shown",
                        screen: "Home",
                        metadata: ["type": String(describing: recommendation).components(separatedBy: "(").first ?? String(describing: recommendation)]
                    )
                }
                await inventoryStore.refreshIfNeededFromView()
            }
            .refreshable {
                await inventoryStore.refreshFromView()
            }
        }
    }

    // MARK: - Tonight hero card

    @ViewBuilder
    private var tonightHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            heroContent

            // Secondary cooking CTAs — always present when pantry is non-empty
            // and the hero isn't already the cookFromPantry two-CTA state
            if showSecondaryCTAs {
                Divider()
                HStack(spacing: 12) {
                    NavigationLink { IngredientInputView() } label: {
                        Text("Cook from pantry")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    NavigationLink { DishSearchView() } label: {
                        Text("I have a dish in mind")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let nutrition = inlineNutrition {
                Divider()
                nutrition
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
    }

    private var showSecondaryCTAs: Bool {
        guard !inventoryStore.usablePantryItems.isEmpty else { return false }
        switch bestNextStep {
        case .cookFromPantry, .none: return false
        default: return true
        }
    }

    @ViewBuilder
    private var heroContent: some View {
        if let recommendation = bestNextStep {
            heroCard(for: recommendation)
        } else if inventoryStore.usablePantryItems.isEmpty {
            emptyPantryHero
        } else {
            cookFromPantryHero
        }
    }

    // Empty pantry — one CTA only
    private var emptyPantryHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your pantry is empty", systemImage: "cabinet")
                .font(.headline)
            Text("Add ingredients to unlock recipe generation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            NavigationLink { PantryView() } label: {
                Text("Add to Pantry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // Has pantry, no specific recommendation — two CTAs
    private var cookFromPantryHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What's for dinner?", systemImage: "fork.knife")
                .font(.headline)
            Text("\(inventoryStore.usablePantryItems.count) items ready in your pantry.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                NavigationLink { IngredientInputView() } label: {
                    Text("Cook from pantry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink { DishSearchView() } label: {
                    Text("I have a dish in mind")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }

    @ViewBuilder
    private func heroCard(for recommendation: HomeRecommendation) -> some View {
        switch recommendation {
        case .expiredReview(let count):
            VStack(alignment: .leading, spacing: 12) {
                Label("Review expired items", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(.red)
                Text("\(count) item(s) are expired and will affect cooking decisions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                NavigationLink { PantryView() } label: {
                    Text("Go to Pantry")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }

        case .favoriteReady(let saved):
            VStack(alignment: .leading, spacing: 12) {
                Label("Favorite ready", systemImage: "star.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                Text(saved.recipe.title)
                    .font(.headline)
                Text("All ingredients are available in your pantry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                heroTwoCTAs(
                    primary: ("Cook This", AnyView(SavedRecipeDetailView(saved: saved))),
                    secondary: ("Something else", AnyView(IngredientInputView()))
                )
            }

        case .stapleReady(let record):
            VStack(alignment: .leading, spacing: 12) {
                Label("Staple ready", systemImage: "flame.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(record.recipeTitle)
                    .font(.headline)
                Text("You've made this before and everything needed is available.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                NavigationLink { CookAgainView(record: record) } label: {
                    Text("Cook Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }

        case .cookAgain(let record):
            VStack(alignment: .leading, spacing: 12) {
                Label("Ready to repeat", systemImage: "arrow.clockwise.heart.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                Text(record.recipeTitle)
                    .font(.headline)
                Text("You made this recently and everything is available again.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                NavigationLink { CookAgainView(record: record) } label: {
                    Text("Cook Again")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }

        case .tonightsPick(let saved, let reason):
            VStack(alignment: .leading, spacing: 12) {
                Label("Tonight's pick", systemImage: "bolt.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
                Text(saved.recipe.title)
                    .font(.headline)
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                heroTwoCTAs(
                    primary: ("Cook This", AnyView(SavedRecipeDetailView(saved: saved))),
                    secondary: ("Something else", AnyView(IngredientInputView()))
                )
            }

        case .savedRecipeReady(let saved):
            VStack(alignment: .leading, spacing: 12) {
                Label("Saved recipe ready", systemImage: "bookmark.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                Text(saved.recipe.title)
                    .font(.headline)
                Text("All ingredients are in your pantry.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                heroTwoCTAs(
                    primary: ("Cook This", AnyView(SavedRecipeDetailView(saved: saved))),
                    secondary: ("Something else", AnyView(IngredientInputView()))
                )
            }

        case .savedRecipeNearMiss(let saved, let missingCount, let reason):
            VStack(alignment: .leading, spacing: 12) {
                Label("Almost ready", systemImage: "cart.badge.plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(saved.recipe.title)
                    .font(.headline)
                Text("Missing \(missingCount) ingredient(s). \(reason)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                heroTwoCTAs(
                    primary: ("View Recipe", AnyView(SavedRecipeDetailView(saved: saved))),
                    secondary: ("Cook something else", AnyView(IngredientInputView()))
                )
            }

        case .useSoon(let items):
            VStack(alignment: .leading, spacing: 12) {
                Label("Use these soon", systemImage: "clock.badge.exclamationmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text(items.map(\.name).joined(separator: ", "))
                    .font(.headline)
                Text("Expiring in your pantry — put them to use tonight.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                heroTwoCTAs(
                    primary: ("Cook with These", AnyView(IngredientInputView())),
                    secondary: ("I have a dish in mind", AnyView(DishSearchView()))
                )
            }

        case .cookFromPantry:
            cookFromPantryHero
        }
    }

    private func heroTwoCTAs(
        primary: (String, AnyView),
        secondary: (String, AnyView)
    ) -> some View {
        HStack(spacing: 12) {
            NavigationLink { primary.1 } label: {
                Text(primary.0).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink { secondary.1 } label: {
                Text(secondary.0).frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Inline nutrition (N1 — one-line text)

    private var inlineNutrition: Text? {
        guard let goals = profileStore.activeProfile?.effectiveNutritionGoals else { return nil }
        let today = cookedMealStore.todayNutrition(for: profileStore.activeProfile)
        return Text("Today  \(today.calories) / \(goals.dailyCalories) kcal  ·  \(today.proteinG) / \(goals.dailyProteinG)g protein")
    }

    // MARK: - Expiring-soon compact banner

    private var showExpiringSoonBanner: Bool {
        guard !inventoryStore.expiringSoonItems.isEmpty else { return false }
        if case .useSoon = bestNextStep { return false }
        return true
    }

    private var expiringSoonBanner: some View {
        NavigationLink {
            PantryView()
        } label: {
            HStack {
                Label("\(inventoryStore.expiringSoonItems.count) item(s) expiring soon", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Computed properties

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

    private var savedRecipes: [SavedRecipe] {
        recipeStore.recipes(for: profileStore.activeProfile)
    }
}

// MARK: - CookAgainView (unchanged, kept here as it's only used from Home)

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
                            metadata: ["recipeTitle": record.recipeTitle, "warningCount": String(warnings.count)]
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
                        metadata: ["recipeTitle": record.recipeTitle, "warningCount": String(warnings.count)]
                    )
                    completionMessage = warnings.isEmpty
                        ? "Pantry updated from what you cooked."
                        : warnings.joined(separator: "\n")
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
