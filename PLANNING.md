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
| **Backend recipe path** | Cloudflare Worker path exists for server-side OpenAI calls with app-token auth; optional local Node relay also exists for development. |
| **Backup / restore** | Local export/import UI exists, app-state backup refresh exists, backend snapshot sync + restore exists behind backend token setup. |
| **Backend auth** | Keychain-backed backend access token flow exists in the app and is used for backend recipe/inventory/snapshot requests. |
| **Inventory sync** | Backend pantry/grocery sync exists with local merge/dedupe behavior and user-visible sync error states. |
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
| **Saved planning hub** | Partially complete. Saved already groups planning-oriented sections, but still needs a more intentional final structure. |

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

1. **Backend sync / backup hardening**
   - backend snapshot sync and restore now exist, so the priority is to harden failure handling, trust boundaries, and test coverage
   - clarify exactly what is local-only, what syncs, what restores, and what happens offline

2. **Move high-value logic out of Views incrementally**
   - `HomeView` still contains too much recommendation logic
   - `SavedRecipesView` now has planning-hub shaping logic that should eventually move toward a dedicated ViewModel/service-backed layer

3. **Harden store decode / persist failures**
   - log decode fallbacks explicitly
   - use debug assertions where encode failures should never be silent
   - make backend auth / sync failures equally intentional and user-visible

### Later

4. **Expand tests beyond the current regression set**
   - add broader store/viewmodel coverage
   - prioritize backend snapshot/auth failure handling, recommendation ranking, planning state derivation, and persistence failure handling

5. **Reduce local environment churn in project settings**
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
| Backend recipe relay (no client OpenAI key) | **Built** | Worker and optional local relay already exist. |
| Backend snapshot backup / restore | **Active** | Implemented, but still needs stronger hardening and clearer failure behavior. |
| Backend inventory sync hardening | **Next** | Existing sync path now needs tighter trust/failure handling and broader tests. |
| Store decode/persist hardening | **Next** | Log silent fallbacks; assert on impossible encode failures in DEBUG. |
| Recipe cache eviction policy | **Built** | Generated recipe cache is now bounded with deterministic eviction tests. |
| Home recommendation extraction | **Next** | Move core recommendation ranking out of `HomeView`. |
| Broader test coverage | **Next** | Extend beyond current regression coverage, especially around sync/auth/restore. |

### Phase B — Complete Recipe-First Planning
**Goal:** let users start from the meal they want, not only from pantry inventory.

| Item | Status | Notes |
|------|--------|-------|
| Reusable planning detail | **Built** | Readiness, grouped ingredients, cook vs grocery CTA. |
| Home -> planning detail routing | **Built** | Saved-recipe recommendations now deep-link into planning detail. |
| Saved planning hub | **Active** | Shape `Saved` into an intent-driven planning hub while keeping full library access. |
| Recipe entry points beyond Saved/Home | **Next** | Add a clearer recipe-first starting surface. |
| Dish-name search | **Later** | Search for a target meal and compare it against pantry. |
| Pantry comparison + grocery add everywhere | **Next** | Reuse planning detail for all recipe-first flows. |

### Phase C — Smart Meal Guidance
**Goal:** make Cookya more proactive about tonight’s decision.

| Item | Status | Notes |
|------|--------|-------|
| Home best-next-step recommendations | **Built** | Core recommendation engine exists today. |
| Stronger tonight suggestion engine | **Later** | AI-backed or heuristic-backed top suggestion card with richer context. |
| Time-aware recipe generation | **Later** | Constrain recipes by available cooking time. |
| Weekly meal planning | **Later** | Generate and manage a weekly meal plan. |
| Grocery generation from meal plans | **Later** | Bulk missing-ingredient generation from planned meals. |
| Stronger repeat-meal prioritization | **Active** | Favorites and staples exist; can be pushed further. |

### Phase D — Shared Household and Multi-Device Sync
**Goal:** move from single-device usefulness to shared-household reliability.

| Item | Status | Notes |
|------|--------|-------|
| Household accounts / auth | **Later** | Required for true shared pantry/grocery. |
| Shared pantry + grocery sync | **Later** | Likely Supabase or equivalent. |
| Multi-profile household logic | **Later** | Current profile logic is local-first. |
| Android/shared household support | **Later** | Important, but after data durability and planning maturity. |

### Phase E — Health and Launch Polish
**Goal:** deepen health usefulness and polish the launch surface once the core loop is fully mature.

| Item | Status | Notes |
|------|--------|-------|
| Nutrition tracking from cooked meals | **Later** | Valuable, but after planning and durability. |
| Whole-food scoring | **Later** | Extend recipe quality signals. |
| Grocery spend / waste reporting | **Later** | Natural extension once data durability improves. |
| Improved onboarding | **Later** | Redesign once the strongest daily-driver story is locked. |
| Share extension / barcode scan | **Later** | Useful convenience features, not current strategic bottlenecks. |
| Offline-first resilience | **Later** | Important when sync architecture becomes real. |

### Recommended near-term order

1. **Backend sync / snapshot hardening**
2. **Home recommendation extraction / architecture cleanup**
3. **Saved planning hub completion**
4. **Recipe-first entry point beyond Saved/Home**
5. **Dish-name search**

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
- branch from `main` for the current slice instead of continuing unrelated work on an old branch
- name the branch after the actual slice, for example:
  - `codex/workflow-rebaseline`
  - `codex/backend-sync-hardening`
  - `codex/home-recommendation-extraction`
  - `codex/saved-planning-hub-polish`

### While working
- work on **one slice at a time**
- keep each daily slice small enough to fit one focused session
- default slice shapes:
  - one architecture cleanup
  - one hardening/test slice
  - one UI/product slice
  - one backend contract slice
- keep `Active`, `Pending`, and `Parked` loops explicit when context switches happen
- avoid bundling unrelated fixes unless they are required for correctness

### After validation
- if a feature or fix is validated, **commit before switching contexts**
- if switching from Codex to Cursor or back, either commit the validated slice or update `WORKLOG.md` with exact in-progress state first
- propose complete, honest commit messages that describe the actual behavior change
- keep git history readable enough to show the project to future collaborators

### Branch hygiene
- `main` is the stable integration branch
- use one short-lived branch per focused slice
- do not keep extending an old branch after its original scope has drifted
- merge or close the slice branch once that slice is validated or explicitly parked

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
