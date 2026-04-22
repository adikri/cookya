# Cookya — Product Planning Document (Reality-Based V2)

> Read this file before starting any task. Treat it as the current product and engineering source of truth. Work one feature at a time, keep planning and implementation explicit, and commit at clean checkpoints with complete commit messages.

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
| Primary (Adi) | iPhone (iOS) | Daily pantry/grocery/cooking operator |
| Partner | Future Android / shared household device | Shared pantry, grocery, meal decisions |

Current product shape:
- shared pantry and grocery conceptually exist in the vision, but the app is still effectively **single-device / single-household-first**
- repeat meals, expiry management, and grocery decisions are now first-class parts of the experience
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
| **Home** | Kitchen command center with best-next-step recommendations, expiry attention, cook-again, saved recipe shortcuts, pantry/grocery management. |
| **Expiry UX** | Expired items excluded from cooking, quick pantry-date review, update expiry, discard expired, batch expiry review flow. |
| **Known items** | Pantry/grocery memory with `Choose from memory`, quantity/category restore, reduced typing. |
| **Logging** | `AppLogger` with session logs, timestamps, in-app debug viewer, export/copy flows. |
| **Standalone app use** | App works away from Xcode on phone with local bundled config/secrets flow. |
| **Tests** | Regression coverage exists for recipe memory, force-refresh, duplicate pantry merge, purchase merge, fresh-vs-expired purchase handling, and blocked mismatch consumption. |

### Active

| Area | Current status |
|------|----------------|
| **Recipe-first planning** | Started. Reusable planning detail exists and Home now routes saved recipe recommendations directly into it. |
| **Saved planning hub** | In progress locally. The next intended shape is a lighter recipe-planning hub backed by the full saved library. |

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

5. **Expand tests beyond the current regression set**
   - add broader store/viewmodel coverage
   - prioritize recommendation ranking, planning state derivation, and persistence failure handling

6. **Reduce local environment churn in project settings**
   - avoid committing signing noise
   - keep the project file stable and intentional

---

## 5. Reality-Based Roadmap

Use these markers consistently:
- **Built** — already shipped in the current branch/product
- **Active** — currently started or partially implemented
- **Next** — should come soon and materially affects product direction
- **Later** — important but not the immediate focus

### Phase A — Protect and Stabilize What Already Works
**Goal:** make the current app safe to rely on daily.

| Item | Status | Notes |
|------|--------|-------|
| Lightweight cloud/data backup | **Built** | KV snapshot via Cloudflare Worker. |
| Backend recipe generation relay (no client OpenAI key) | **Built** | Cloudflare Worker with static token auth. |
| Store decode/persist hardening | **Built** | AppLogger on decode fallbacks; assertionFailure on encode failures in all stores. |
| Recipe cache eviction policy | **Built** | GeneratedRecipeCachePolicy: LRU eviction, cap of 50, tested. |
| Home recommendation extraction | **Built** | `HomeRecommendationEngine` extracted with full test coverage. |
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

### Phase B — Complete Recipe-First Planning
**Goal:** let users start from the meal they want, not only from pantry inventory. **Deferred until after Phase N.**

| Item | Status | Notes |
|------|--------|-------|
| Reusable planning detail | **Built** | Readiness, grouped ingredients, cook vs grocery CTA. |
| Home -> planning detail routing | **Built** | Saved-recipe recommendations now deep-link into planning detail. |
| Saved planning hub | **Next** | Nutrition layer is now in. Richer view of saved recipes with readiness, macros, and goal fit. |
| Recipe entry points beyond Saved/Home | **Next** | Add a clearer recipe-first starting surface. |
| Dish-name search | **Later** | Search for a target meal and compare it against pantry. |
| Pantry comparison + grocery add everywhere | **Next** | Reuse planning detail for all recipe-first flows. |

### Phase C — Smart Meal Guidance
**Goal:** make Cookya more proactive about tonight’s decision.

| Item | Status | Notes |
|------|--------|-------|
| Home best-next-step recommendations | **Built** | `HomeRecommendationEngine` extracted and tested. |
| Tonight’s pick (single opinionated answer) | **Built** | Part of Phase N — `HomeRecommendationEngine` extended with nutrition gap. |
| Weekly meal planning | **Next** | Pick 5-7 meals for the week, auto-generate grocery list. Follows Phase N. |
| Meal prep suggestions | **Next** | "Prep X on Sunday for Monday + Tuesday." Follows weekly planning. |
| Time-aware recipe generation | **Later** | Constrain recipes by available cooking time. |
| Grocery generation from meal plans | **Later** | Bulk missing-ingredient generation from planned meals. |
| Stronger repeat-meal prioritization | **Active** | Favorites and staples exist; can be pushed further. |

### Phase D — Production Foundation
**Goal:** multi-device, real auth, durable data. Can begin in parallel with Phase C.

| Item | Status | Notes |
|------|--------|-------|
| Move to Supabase | **Next** | PostgreSQL, real auth (Apple Sign In), real-time sync, iOS + Android SDKs. Replaces UserDefaults + KV for user data. Keep Cloudflare Worker as OpenAI relay. |
| Push notifications | **Next** | Expiring items, "you haven’t planned dinner yet." Requires Supabase auth first. |
| Household accounts / multi-profile | **Later** | After Supabase is in place. |
| Android via React Native | **Later** | After iOS experience is solid. |

### Recommended near-term order

1. ~~`codex/nutrition-layer` — Recipe macros + NutritionGoals in UserProfile + OpenAI schema~~ **Done**
2. ~~`codex/nutrition-home` — Home progress card + tonight’s pick~~ **Done**
3. ~~Quick cleanup: store decode hardening + recipe cache eviction~~ **Done**
4. `codex/saved-planning-hub` — saved recipes with readiness, macros, and goal fit **← current**
5. `codex/weekly-meal-plan` — weekly planning + grocery generation
6. `codex/supabase-foundation` — real auth + sync (can overlap with #5)

---

## 6. Architecture Conventions

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

## 7. Working Rules for Codex / Engineering Workflow

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
