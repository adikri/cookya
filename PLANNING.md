# Cookya — Product Planning Document (Reality-Based V2)

> Read this file before starting any task. Treat it as the current product and engineering source of truth. Work one feature at a time, keep planning and implementation explicit, and commit at clean checkpoints with complete commit messages.

> **Market context:** see `docs/COMPETITIVE.md` for the competitive landscape, UI/UX references for the Android rewrite, and strategic positioning. Refresh that doc when a major competitor ships a category-shifting feature.

---

## 1. Product Vision

Cookya is a household cooking OS that helps answer the one question that matters every day:
**what should we cook tonight?**

The product is now shaped around two complementary modes:
- **Pantry-first:** What can I cook from what I already have?
- **Recipe-first:** I want to cook this. What do I need?

The core loop remains:
**Pantry -> Recipe decision -> Grocery action -> Cook -> Update pantry -> Repeat**

The difference now is that Cookya is no longer just trying to generate recipes. It is becoming a reliable kitchen decision layer built on inventory trust, repeatability, and low-friction household maintenance.

---

## 2. Users and Product Shape

| User | Device | Current Role in Product |
|------|--------|-------------------------|
| Primary (Adi) | iPhone (iOS SwiftUI) | Personal daily driver + feature test bed. Not on App Store — no paid Apple Developer account. |
| Android users (public) | Android (React Native) | Play Store target. Real-world feedback. Email + Google Sign In. |
| Partner | Future Android / shared household | Shared pantry, grocery, meal decisions — enabled by Supabase multi-user. |

Current product shape:
- iOS SwiftUI app is the personal prototype environment — new ideas are validated here first
- Android React Native app is the public production target — features ship here for real user feedback
- Supabase is the shared backend that connects both platforms
- the strongest current product behavior is **trustworthy pantry-driven cooking**

---

## 3. Current Product State

### Built

| Area | Current reality |
|------|-----------------|
| **Pantry** | Full CRUD, duplicate merging, structured quantity input, expiry separation (`Use Soon`, `Available`, `Expired`), quick quantity adjust, expiry review flow, add-to-grocery, undo delete. |
| **Grocery** | Full CRUD, duplicate merging, known-item reuse, meal-aware source/reason tracking, near-miss suggestions, purchase -> pantry confirmation flow, purchase readiness feedback, undo delete. |
| **Purchase flow** | Purchase now confirms quantity, category, and expiry before pantry entry. Fresh purchases stay separate from expired pantry stock. |
| **Recipe generation** | OpenAI + backend relay path, normalized request identity, recipe memory, `Generate Another Recipe`, structured logging. |
| **Cooked flow** | `Cooked This`, pantry decrement, blocking on unsafe quantity/unit mismatches, cooked history creation, replay/cook-again support. |
| **Saved recipes** | Save, favorite, readiness sorting, reusable planning detail, Home deep-links into planning detail. |
| **Repeat meals** | Favorites, staples, cook again, saved readiness, Home recommendation support. |
| **Home** | Kitchen command center with best-next-step recommendations, expiry attention, cook-again, saved recipe shortcuts, pantry/grocery management, today's nutrition progress card, tonight's pick. |
| **Expiry UX** | Expired items excluded from cooking, quick pantry-date review, update expiry, discard expired, batch expiry review flow. |
| **Known items** | Pantry/grocery memory with `Choose from memory`, quantity/category restore, reduced typing. |
| **Logging** | `AppLogger` with session logs, timestamps, in-app debug viewer, export/copy flows. |
| **Standalone app use** | App works away from Xcode on phone with local bundled config/secrets flow. |
| **Tests** | Regression coverage exists for recipe memory, force-refresh, duplicate pantry merge, purchase merge, fresh-vs-expired purchase handling, blocked mismatch consumption, recommendation engine priority and nutrition-gap logic. |
| **Nutrition layer** | Macros on recipes + cooked records, NutritionGoals auto-calculated from biometrics, goal-aware generation, daily progress card, tonight's pick recommendation. |
| **Saved planning hub** | Saved recipes grouped by readiness with macro data and goal-fit context per recipe. |
| **Weekly meal plan** | Plan tab: pick up to 7 saved recipes, missing ingredients deduplicated across all meals, one-tap grocery generation. |

### Active

| Area | Current status |
|------|----------------|
| **Recipe-first entry points** | Planning detail and saved hub are built. Still needs a clearer recipe-first starting surface beyond Saved/Home. |

### Strengths of the current app

1. **Pantry trust is much stronger than before**
   - duplicate items merge
   - unsafe pantry updates are blocked
   - fresh and expired stock are not conflated
   - quick maintenance flows reduce drift

2. **Repeat cooking is now a real product pillar**
   - saved recipes, cook again, favorites, staples, readiness sorting, and Home recommendation all reinforce repeatable meals

3. **Grocery is connected to cooking intent**
   - near-miss suggestions
   - recipe-aware reasons
   - purchase feedback when a meal becomes cookable

4. **The app is usable in real life now**
   - standalone phone usage works
   - the core household loop is usable without Xcode attached

---

## 4. Current Engineering Debt / Hardening Priorities

These are the main technical priorities that still matter.

### Next

1. **Move high-value logic out of Views incrementally**
   - `HomeView` still contains too much recommendation logic
   - `SavedRecipesView` now has planning-hub shaping logic that should eventually move toward a dedicated ViewModel/service-backed layer

### Done (no longer open)

- **Data durability / backup** — KV snapshot via Cloudflare Worker.
- **Recipe cache eviction policy** — `GeneratedRecipeCachePolicy`: LRU, capped at 50, tested.
- **Harden store decode / persist failures** — `AppLogger` on all decode fallbacks; `assertionFailure` on encode failures in all stores.

### Later

2. **Expand tests beyond the current regression set**
   - add broader store/viewmodel coverage
   - prioritize planning state derivation and persistence failure handling

3. **Reduce local environment churn in project settings**
   - avoid committing signing noise
   - keep the project file stable and intentional

---

## 5. Reality-Based Roadmap

Use these markers consistently:
- **Built** — landed on `main`
- **Built (on `<branch>`, awaiting merge to main)** — code exists and is validated on the named branch but has not yet been merged into `main`. When that branch lands, drop the parenthetical.
- **Active** — currently started or partially implemented
- **Next** — should come soon and materially affects product direction
- **Later** — important but not the immediate focus

> **Reality vs `main` (as of 2026-05-02):** the Supabase migration and the React Native Android app are largely built on `codex/react-native-android` (which supersedes `codex/supabase-store-sync`) but have not yet been merged to `main`. Items below tagged with that branch reflect work that exists in the repository but has not landed on the trunk. Merging that branch is the highest-leverage next step — until then, `main` is several phases behind reality.

### Phase A — Protect and Stabilize What Already Works
**Goal:** make the current app safe to rely on daily.

| Item | Status | Notes |
|------|--------|-------|
| Lightweight cloud/data backup | **Built** on `main` (KV snapshot via Cloudflare Worker); **superseded** on `codex/react-native-android` by Supabase `user_snapshots` JSONB backup via `SupabaseSnapshotService`. |
| Backend recipe generation relay (no client OpenAI key) | **Built** | Cloudflare Worker with static token auth. |
| Store decode/persist hardening | **Built** | AppLogger on decode fallbacks; assertionFailure on encode failures in all stores. |
| Recipe cache eviction policy | **Built** | GeneratedRecipeCachePolicy: LRU eviction, cap of 50, tested. |
| Home recommendation extraction | **Built** | `HomeRecommendationEngine` extracted with full test coverage. |
| Inventory local-only sync recovery | **Built (on `codex/react-native-android`, awaiting merge to main)** | `InventoryStore.refresh()` uploads local-only pantry/grocery rows missing in Supabase; validated on device. |
| Snapshot upload deduping | **Built (on `codex/react-native-android`, awaiting merge to main)** | `AppBackupCoordinator` coalesces rapid local persistence changes into one backend snapshot upsert; validated on device. |
| Auth/session reliability | **Built (on `codex/react-native-android`, awaiting merge to main)** | `AuthStore` observes Supabase auth state changes after launch; root view responds to sign-in/out/token-refresh without relaunch. Validated on device. |
| Broader test coverage | **Later** | Extend beyond current regression coverage. |

### Phase N — Nutrition Layer (current priority)
**Goal:** shift the product from "recipe generator" to "nutrition goal assistant."

The use case is a health-conscious user who wants nutritionally dense home-cooked food without the mental overhead of planning. The app currently has no nutrition data and no goal layer.

| Item | Status | Notes |
|------|--------|-------|
| Macros on Recipe (protein, carbs, fat, fiber) | **Built** | OpenAI structured output schema extended. `CookedMealRecord` and `SavedRecipe` carry macro snapshots. |
| NutritionGoals in UserProfile | **Built** | Auto-calculated from weight/height/age (Mifflin-St Jeor); user-overridable. |
| Today’s nutrition progress on Home | **Built** | Calories + protein progress bars on HomeView, derived from `CookedMealStore.todayNutrition`. |
| Goal-aware recipe generation | **Built** | Daily nutrition gap passed to OpenAI prompt on both iOS and Worker paths. |
| "Tonight’s pick" — one opinionated answer | **Built** | `HomeRecommendationEngine` promotes highest-protein ready recipe when gap > 20g, with visible reason string. |

Branch plan: `codex/nutrition-layer` (model + schema) → `codex/nutrition-home` (UI + recommendation engine).

### Phase E — Data Quality at Entry
**Goal:** prevent bad data from entering the pantry/grocery before it can sync to Supabase and affect recipe generation, readiness detection, and nutrition tracking.

| Item | Status | Notes |
|------|--------|-------|
| Catalog-backed item picker | **Built (on `codex/react-native-android`, awaiting merge to main)** | `PantryItemCatalog` with ~290 items (including Indian staples). `KnownItemPickerView` redesigned: search-first with 3-col category grid, recent items capped at 5, category drill-down, "Add new item" always visible. Picker is the primary Add entry point in PantryView and GroceryListView. |
| Fuzzy autocomplete on known items | **Later** | Picker already filters catalog + history. Deeper fuzzy matching ("tomatoe" → "Tomatoes") can be added later if needed. |
| Unit canonicalization picker | **Later** | `QuantityInputView` already has Quick Pick mode. Full enforcement deferred. |

### Phase B — Complete Recipe-First Planning
**Goal:** let users start from the meal they want, not only from pantry inventory. **Deferred until after Phase N.**

| Item | Status | Notes |
|------|--------|-------|
| Reusable planning detail | **Built** | Readiness, grouped ingredients, cook vs grocery CTA. |
| Home -> planning detail routing | **Built** | Saved-recipe recommendations now deep-link into planning detail. |
| Saved planning hub | **Built** | Saved recipes with readiness badges, macros per row, goal-fit context in detail view. |
| Recipe entry points beyond Saved/Home | **Built (on `codex/react-native-android`, awaiting merge to main)** | `DishSearchView`: type a dish name → generate recipe targeting that dish using available pantry as context. Accessible from Home hero "I have a dish in mind" CTA. |
| Dish-name search | **Later** | Search for a target meal and compare it against pantry. |
| Pantry comparison + grocery add everywhere | **Next** | Reuse planning detail for all recipe-first flows. |

### Phase C — Smart Meal Guidance
**Goal:** make Cookya more proactive about tonight’s decision.

| Item | Status | Notes |
|------|--------|-------|
| Home best-next-step recommendations | **Built** | `HomeRecommendationEngine` extracted and tested. |
| Tonight’s pick (single opinionated answer) | **Built** | Part of Phase N — `HomeRecommendationEngine` extended with nutrition gap. |
| Weekly meal planning | **Built** | Plan tab: up to 7 saved recipes, missing ingredients deduplicated across all meals, one-tap grocery generation. |
| Meal prep suggestions | **Next** | "Prep X on Sunday for Monday + Tuesday." Follows weekly planning. |
| Time-aware recipe generation | **Later** | Constrain recipes by available cooking time. |
| Grocery generation from meal plans | **Built** | Part of the weekly meal plan — "Add All to Grocery" covers all planned meals in one tap. |
| Stronger repeat-meal prioritization | **Active** | Favorites and staples exist; can be pushed further. |

### Phase D — Production Foundation
**Goal:** Supabase backend shared by iOS and Android. Android React Native app on Play Store is the primary public distribution target. iOS SwiftUI stays as personal daily driver and test bed. No paid Apple Developer account — Apple Sign In deferred.

| Item | Status | Notes |
|------|--------|-------|
| Supabase auth (email + Google) | **Built (on `codex/react-native-android`, awaiting merge to main)** | Email/password and Google Sign In wired. Apple Sign In deferred (requires paid Apple Developer). |
| Supabase database schema + RLS | **Built (on `codex/react-native-android`, awaiting merge to main)** | 6 tables (pantry, grocery, saved_recipes, cooked_meal_records, weekly_plan_meals, profiles). RLS enabled on all tables. Migration in `supabase/migrations/20260423_initial_schema.sql`. |
| iOS Supabase integration — inventory | **Built (on `codex/react-native-android`, awaiting merge to main)** | `SupabaseInventoryService` replaces `BackendInventoryService` for pantry/grocery CRUD. Cloudflare Worker KV inventory endpoints no longer used. |
| iOS Supabase integration — snapshot | **Built (on `codex/react-native-android`, awaiting merge to main)** | `SupabaseSnapshotService` replaces `BackendSnapshotService`. Full backup stored as JSONB in `user_snapshots` table. Cloudflare Worker is now OpenAI relay only. |
| iOS Supabase integration — all stores | **Built (on `codex/react-native-android`, awaiting merge to main)** | `RecipeStore`, `CookedMealStore`, `ProfileStore`, `WeeklyPlanStore` sync to Supabase via injected services. Optimistic local update + background sync on every mutation. All 7 Supabase tables live. |
| React Native Android app | **Active (on `codex/react-native-android`, awaiting merge to main)** | Expo SDK 54 / RN 0.81.5. Auth, pantry, grocery, recipe generation, profile + sign-out, weekly plan, nutrition, item picker, home recommendations all built and web-validated. Android device test pending. See section 6 below. |
| Push notifications | **Later** | Expiring items, "haven't planned dinner yet." Requires Supabase auth first. |
| Household accounts / shared pantry | **Later** | After Supabase is in place. Key feature for partner sharing. |
| iOS App Store distribution | **Later** | Requires paid Apple Developer account ($99/yr) — deferred. |

### Recommended near-term order

1. ~~`codex/nutrition-layer`~~ **Done** (on main)
2. ~~`codex/nutrition-home`~~ **Done** (on main)
3. ~~`codex/saved-planning-hub`~~ **Done** (on main)
4. ~~`codex/weekly-meal-plan`~~ **Done** (on main)
5. ~~`codex/supabase-foundation` / `codex/supabase-store-sync`~~ **Done on branch, not yet merged to main** — Supabase auth + schema + iOS integration for all 7 stores
6. **Merge `codex/react-native-android` to main** ← **highest-leverage next step** — supersedes (5) since it builds on top of it; brings Supabase + Android RN onto the trunk
7. `codex/android-device-validation` — finish Android device testing for parity slices M1–H5
8. `codex/android-play-store-prep` — release build, signing, store listing assets

---

## 6. Android Roadmap — parity slices

Branch: `codex/react-native-android`. Each slice: typecheck → Jest → manual web → Android device → WORKLOG → commit. All slices below are Built on the branch; only Android device validation remains.

| Slice | What | Status |
|---|---|---|
| M1 | Auth, pantry, grocery, recipe gen, profile + sign-out | **Built** — web-validated |
| M2 | Category picker (9 categories matching iOS), error display on all screens | **Built** |
| M3 | Save recipes — Save button, Saved tab, `savedRecipeStore` | **Built** |
| M4 | User profile + dietary prefs — passed to recipe gen | **Built** |
| M5 | Cooked meal history — "I cooked this" on any recipe, `cookedMealStore` | **Built** |
| M6 | Nutrition progress on Home — today's macros vs profile goals | **Built** |
| M7 | Weekly meal planning — up to 7 meals, missing ingredients, add to grocery | **Built** |
| M8 | Home recommendation engine — tonight's pick based on nutrition gap | **Built** |
| M9 | Known items / catalog — 290-item search-first picker | **Built** |
| M10 | Expiry dates on pantry items | **Built** |
| H1 | Home screen layout — greeting, Let's Cook hero, Kitchen Management cards | **Built** |
| H2 | Nutrition progress on Home (calories + protein bars) | **Built** |
| H3 | Best Next Step — fill-pantry / tonight-pick / cook-favorite | **Built** |
| H4 | Attention Needed — expiring pantry items (≤ 3 days) with colored labels | **Built** |
| H5 | Cook Faster — favorites-first saved recipe shortcuts, cap 3, see-all link | **Built** |

---

## 7. Architecture Conventions

This is still a **SwiftUI MVVM-leaning app with protocol-driven services**, but the codebase is not yet perfectly strict MVVM. Treat that honestly.

### Keep doing this
- new services: protocol first, implementation second
- new ViewModels: `@MainActor final class`, `ObservableObject`, dependency injection via `init`
- injected dependencies instead of hardcoding `UserDefaults.standard` in new code
- `AppLogger` for significant actions, decisions, and failures
- tests for new services/ViewModels and for critical behavior changes

### Current reality to respect
- some business/recommendation logic still lives in Views
- do not pretend the app is already fully ViewModel-extracted
- extract incrementally when a View becomes hard to reason about or too stateful

### Store conventions
- prefer injected `UserDefaults`, encoder, decoder where practical
- `@Published private(set)` for store-owned state
- log decode fallback paths explicitly
- use `assertionFailure` in DEBUG where persist failures should never be silent

### AI service conventions
- all LLM calls go through protocol-backed services
- keep structured output / schema-backed parsing
- surface and log: missing key, rate limit, decode failure, network failure, cancellation

### Repo-specific SwiftUI rule
This repo/compiler setup is sensitive to SwiftUI section syntax.

Always prefer:
```swift
Section {
    ...
} header: {
    Text("...")
} footer: {
    ...
}
```

Avoid:
```swift
Section("...") {
    ...
}
```

Also:
- keep section headers simple
- avoid interactive controls directly in section headers unless already proven safe in this repo

### Do not do this
- do not add third-party dependencies casually
- do not mix unrelated Xcode signing/project churn into feature commits
- do not put new heavy decision logic into Views if a ViewModel/service boundary is already warranted
- do not change service protocols casually without updating all conformances and tests

---

## 8. Working Rules for Codex / Engineering Workflow

### Before starting work
- read `PLANNING.md`
- ground in the actual repo state first
- identify whether the task is a feature, hardening, cleanup, or planning work

### While working
- work on **one feature at a time**
- keep `Active`, `Pending`, and `Parked` loops explicit when context switches happen
- avoid bundling unrelated fixes unless they are required for correctness

### After validation
- if a feature or fix is validated, **commit before switching contexts**
- propose complete, honest commit messages that describe the actual behavior change
- keep git history readable enough to show the project to future collaborators

### Commit hygiene
- commit only the files that belong to the current task
- inspect project-file churn before committing it
- avoid accidental signing-only or local-environment diffs

### Testing expectations
- add tests for new services and ViewModels
- add targeted regression tests for critical behavior changes even when the change is not ViewModel-based
- when local simulator execution is blocked, be explicit about the limitation instead of claiming test success

### Recommended task prompt shape
```text
Context: Read PLANNING.md first.
Task: Implement [feature/fix].
Constraints:
- Follow current architecture conventions in PLANNING.md
- Keep logic out of Views when a boundary is warranted
- Add tests for critical behavior changes
- Use AppLogger for significant events
- Commit at a clean checkpoint before switching tasks
```
