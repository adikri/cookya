# Cookya Worklog

Use this file to keep daily planning and end-of-day progress visible.

## Daily workflow

### Start of day
- Fill in `Must Do`, `Nice to Have`, and `Watch`
- Keep the list short enough that we can realistically finish it

### During the day
- Move items between `In Progress`, `Done`, `Blocked`, and `Carry Forward`
- Commit validated work at clean checkpoints instead of batching unrelated changes

### End of day
- Record what actually got done
- List commits created that day
- Note what carries into the next session
- Push to GitHub after the wrap-up

---

## 2026-04-26 — Android Home screen H3+H4+H5

### Done
- Created `mobile/services/homeRecommendationEngine.ts` — pure TS function with discriminated union output (`fill-pantry | tonight-pick | cook-favorite | null`); priority: pantry empty → protein gap + saved recipe → saved favorite → null
- Folded standalone Tonight's Pick logic into the engine (one recommendation surface instead of two)
- Added **H3: Best Next Step** — renders the engine output as a contextual card (fill-pantry = orange, tonight-pick = green, cook-favorite = primary blue)
- Added **H4: Attention Needed** — expiry-aware pantry warning section; items expiring ≤ 3 days shown with colored labels; expiry math done in local timezone (YYYY-MM-DD string compare, not UTC Date objects)
- Added **H5: Cook Faster** — favorites-first saved recipe list, capped at 3 rows, "See all" link when more exist
- `npm run typecheck` clean, `npm test` 61/61

### Carry Forward
- Android device validation session (QR scan with Expo Go, verify all Home sections on device)

---

## 2026-04-24 — Slice H1: Home screen structure + design tokens

### Done
- Created `mobile/theme.ts` — colors, spacing, typography, radius tokens matching iOS
- Created `mobile/components/SectionHeader.tsx`, `ActionCard.tsx`, `ManagementCard.tsx`
- Rewrote `mobile/app/(tabs)/index.tsx` with iOS Home layout:
  - Greeting ("What's cooking [email]?!")
  - Let's Cook hero card with pantry chip and inline recipe generation
  - Kitchen Management cards (Pantry + Grocery, live item counts, navigate to tabs)
  - Stub comments for H2 (Nutrition), H3 (Best Next Step), H4 (Attention Needed), H5 (Cook Faster)
- Hidden Home tab header (greeting is the page title)
- `npm run typecheck` clean, `npm test` 28/28

### Carry Forward (next slices)
- H2: ProfileStore + CookedMealStore → nutrition progress card
- H3: HomeRecommendationEngine (pure TS) → Best Next Step
- H4: Expiry filters on pantryStore → Attention Needed
- H5: RecipeStore → Cook Faster section

---

## 2026-04-24 — Mobile test infrastructure + Android device setup

### Done
- Diagnosed Android device testing: Expo Go + QR code requires no SDK; USB/ADB path requires Android Studio
- Installed missing expo-router peer deps: `react-native-safe-area-context`, `react-native-screens`, `react-native-gesture-handler`
- Fixed 2 TypeScript bugs: `ListEmptyContent` → `ListEmptyComponent` in `pantry.tsx` and `grocery.tsx`
- Fixed `recipeService.ts` to read env vars inside the function (module-level constants break Jest)
- Set up Jest (jest-expo ~54, @testing-library/react-native, @types/jest)
- Wrote 28 unit tests across 4 files: `pantryStore`, `groceryStore`, `authStore`, `recipeService`
- Added `npm run typecheck` and `npm test` scripts to `mobile/package.json`
- Used smoke-test layout (`<Text>Cookya boots ✓</Text>`) to confirm Layer 1 (bundle renders) before restoring auth
- Confirmed web build works at `localhost:8081` via `npx expo start --web`
- Documented all mobile rules in `CLAUDE.md` under new `mobile/` section

### Lessons captured in CLAUDE.md
- Expo Go QR path vs USB/ADB path and when each is needed
- expo-router peer dep list
- Env vars inside functions rule (testability)
- Zustand v5 setState partial merge in tests
- Smoke-test layout pattern for blank-screen debugging
- `ListEmptyComponent` correct prop name

### Carry Forward
- Android testing: parked until device is available again — run `npm run typecheck && npm test` first, then `npx expo start` + QR scan
- Web testing flow: `npx expo start --web --clear` → sign up at localhost:8081 → verify auth → pantry/grocery CRUD

---

## 2026-04-24 — iOS inventory local-only sync hardening

### Done
- Added `InventoryStore.refresh()` recovery path for local-only pantry/grocery rows that exist on-device but are missing in Supabase
- Removed silent failure swallowing during local-only upload so refresh now surfaces sync errors instead of reporting false success
- Added regression tests for:
  - pantry local-only upload
  - grocery local-only upload
  - no re-upload when the row already exists remotely
  - no upload when local inventory is empty
  - failure-path sync error reporting for pantry/grocery local-only uploads
- Added `SupabaseErrorDiagnostics` to log underlying Supabase request failures with structured metadata
- Fixed `Swift.CancellationError` mapping so cancelled view-bound sync work is no longer misreported as `networkError`
- Decoupled view-triggered inventory refresh from SwiftUI task cancellation via `refreshFromView()` / `refreshIfNeededFromView()`

### Validated
- `Cmd + B`
- `InventoryStoreTests`
- `SupabaseErrorDiagnosticsTests`
- Manual iPhone flow:
  - created a true local-only pantry item while offline
  - confirmed it was absent in Supabase before refresh
  - restored connectivity
  - pulled to refresh on Home
  - observed `inventory_sync_uploading_local_only` and `inventory_sync_succeeded`
  - confirmed the row appeared in Supabase after refresh

### Carry Forward
- Snapshot backup currently logs multiple `backend_snapshot_upsert_succeeded` events around a single pantry save; investigate and deduplicate that path as a separate slice

---

## 2026-04-24 — iOS snapshot upload deduping

### Done
- Added backend snapshot upload coalescing inside `AppBackupCoordinator`
- Rapid `UserDefaults` changes now collapse into one remote snapshot upsert instead of firing a backend write per defaults notification
- Added immediate flush behavior when the app moves to inactive/background so the latest snapshot is still uploaded promptly on lifecycle exit
- Added regression coverage proving multiple rapid local persistence changes result in one snapshot upload carrying the latest combined state

### Validated
- `Cmd + B`
- `AppBackupCoordinatorTests`
- `InventoryStoreTests`
- `SupabaseErrorDiagnosticsTests`
- Manual iPhone flow:
  - saved one pantry item
  - verified only one `backend_snapshot_upsert_succeeded` event around that save

### Carry Forward
- Worker/mobile/doc changes already in the branch remain uncommitted and should stay isolated from this iOS slice

---

## 2026-04-25 — Backup/restore durability (B1) + auth test reliability fix

### Done
- Extended `MockSnapshotSyncService` with configurable `fetchLatestResult` and `fetchLatestCallCount` recorder
- Added 5 tests for `AppBackupCoordinator.restoreFromBackendIfNeeded()`:
  - happy path: applies backup when local state is empty
  - guard: does not fetch when local state is present (live data not overwritten)
  - silent ignore: `.notFound`
  - silent ignore: `.notAuthenticated`
  - silent handle: `.networkError`
- Fixed flaky auth state change tests: replaced single `Task.yield()` with `drainObservers()` (3 yields) to cover the MainActor scheduling cycles needed for `AsyncStream` delivery

### Validated
- `Cmd + B` ✓
- `AppBackupCoordinatorTests` — 8/8 ✓
- `AuthStoreTests` — all passing ✓

### Carry Forward
- Priority 4: per-store sync verification (RecipeStore, CookedMealStore, ProfileStore, WeeklyPlanStore)

---

## 2026-04-25 — Per-store sync verification (S1)

### Done
- Created `cookyaTests/StoreSyncTests.swift` with 4 test classes (one per store)
- `RecipeStoreSyncTests`: save→upsertSavedRecipe, remove→deleteSavedRecipe, nil-service local-only
- `CookedMealStoreSyncTests`: addRecord→upsertRecord, deleteRecord→deleteRecord, nil-service local-only
- `ProfileStoreSyncTests`: createRegisteredProfile→upsertProfile, nil-service local-only
- `WeeklyPlanStoreSyncTests`: add→upsertMeal, remove→deleteMeal, clearAll→clearAllMeals, nil-service local-only
- All 4 mocks record calls and expose reset(); drainSync() helper reuses 3-yield pattern from auth tests

### Validated
- `Cmd + B` ✓
- `StoreSyncTests` — 13/13 ✓
- Full suite still green ✓

### Carry Forward
- iOS hardening priorities complete — decide next: Android/mobile or further iOS work

---

## 2026-04-25 — iOS auth/session reliability

### Done
- `AuthServiceProtocol` now exposes Supabase `authStateChanges`
- `AuthStore` observes Supabase auth state changes after launch; updates session on `SIGNED_IN`, `TOKEN_REFRESHED`, `USER_UPDATED`, `PASSWORD_RECOVERY`, `MFA_CHALLENGE_VERIFIED`; clears session on `SIGNED_OUT`, `USER_DELETED`; cancels observer on deinit
- Added `AuthStoreTests` coverage for post-launch signed-in event, signed-out event, and token-refresh replacing the active session

### Validated
- `Cmd + B` ✓
- `AuthStoreTests` ✓
- Manual iPhone flow ✓ — sign out → `SignInView` appears immediately; sign in → `MainTabView` appears immediately; no relaunch required

### Carry Forward
- Remaining RESUME priority order: backup/restore durability → per-store sync verification → Android/mobile

**When resumed work completes**, Claude adds a `### Session Resumed` block to that day's entry:
```
### Session Resumed — <date> ~<time>
*(Carried from interrupted session)*
- Was working on: <...>
- Done at resume: <...>
```

---

## 2026-04-23 (session 5)

### Done
- Audited codebase for security, testing, logging, and debugging gaps (comprehensive agent report)
- Added 11 tests to `WeeklyPlanStoreTests`: CRUD, max capacity, persistence, bad data recovery
- Fixed AppConfig to support `nonisolated init` with default Supabase parameters for backward compatibility
- Added security decision to DECISIONS.md: which keys are safe to bundle + RLS as critical prerequisite for Supabase
- Updated PLANNING.md: flagged RLS as required before schema goes live

### Commits
- `5daf574` Add WeeklyPlanStore tests: CRUD, max capacity, persistence, bad data

### Audit Summary (gaps identified)

**Security**
- Worker rate limiting is in-memory only (no KV persistence)
- No CORS restrictions on Worker endpoints
- Supabase publishable key bundled — safe only with RLS in place

**Testing** — Critical gap
- AuthStore (session 4 work): 0 tests
- CookedMealStore nutrition methods: 0 tests
- NutritionGoals formula: 0 tests
- WeeklyPlanStore: **11 tests added this session** ✅
- Supabase integration: 0 tests
- Weekly plan view logic: 0 tests
- 25 existing regression tests (strong base)

**Logging** — Significant gap
- Missing: SupabaseManager init logging, CookedMealStore add/delete tracking, profile onboarding completion, which recommendation was shown on Home, recipe generation fallback path
- Missing: request/response logging for network calls, performance timing, structured log levels
- No AppLogger in 6 new files from sessions 3–4

**Debugging**
- No real-time console output (AppLogger writes to files only)
- No request/response inspection for network failures
- No performance metrics on async operations
- DebugLogsView is DEBUG-only

### Next Tech Debt Work (priority order)
1. ~~Add logging to: SupabaseManager init, CookedMealStore add/delete, recipe generation fallback, recommendation display~~ ✅ Done session 6
2. ~~AuthStore tests (mock Supabase SDK, test all 4 paths + error cases)~~ ✅ Done session 6
3. Request/response logging for critical network calls

## 2026-04-24 (session 7)

### Done
- **Item picker slice**: Replaced free-text-first Add flow with catalog-backed picker as the primary entry point for pantry and grocery. `PantryItemCatalog` with ~290 items (global + Indian staples). `KnownItemPickerView` upgraded to show history first, then catalog items not in history, plus "Add new item" fallback. `PantryItemEditorView` and `GroceryItemEditorView` accept `prefill` param and no longer show inline "Choose from memory" button. Added Indian pantry staples after testing revealed moong dal was missing; saved cooking context to memory for future sessions.

- **Supabase store sync slice**: Added `StoreSyncProtocols` (4 protocols + `StoreSyncError`) and `SupabaseStoreSyncServices` (4 implementations). `RecipeStore`, `CookedMealStore`, `ProfileStore`, `WeeklyPlanStore` all accept injected sync services and push mutations to Supabase in the background. All 7 Supabase tables now live. Added direct-fields init to `PlannedMeal` for DTO reconstruction.
- **Item picker UX redesign**: `KnownItemPickerView` replaced flat catalog list with search-first + 3-col category grid (SF Symbol icons per category via `InventoryCategory.icon`). Empty state shows recent items + category grid + "Add new item" — no scrolling needed. Tapping a category drills into that category's items. Search still filters full catalog + history.

### Commits
- `152dba0` Add catalog-backed item picker as primary Add entry point for pantry and grocery
- `268f926` Sync all remaining stores to Supabase; all 7 tables now live
- `c9a14d0` Redesign item picker: search-first with category grid and icons

### Key learnings this session
- **Item picker discoverability**: flat catalog list of 30 items is worse UX than a compact category grid — users don't know what to look for, they need structure
- **Indian pantry staples must always be in the catalog**: moong dal, toor dal, besan, atta, ghee etc. — saved to memory so future sessions don't miss this
- **Category icons improve scannability**: `InventoryCategory.icon` added; reusable across the app wherever categories are displayed
- **Supabase sync architecture is complete**: all 7 tables live, all stores syncing optimistically — app is now production-grade on data durability

### Carry Forward
- Expand catalog as new items are discovered missing during real use
- Android React Native app (`codex/react-native-android`) — next major milestone for public launch
- Session refresh / token expiry handling (Supabase auth token ~1hr TTL)

---

## 2026-04-23 (session 6)

### Done
- **Logging slice**: Added AppLogger to SupabaseManager init, CookedMealStore add/delete, BackendRecipeService fallback paths (both), HomeView recommendation display
- **AuthStore tests slice**: Extracted `AuthServiceProtocol` + `LiveAuthService` to make AuthStore testable without a real Supabase client; exposed `sessionRestoreTask` for awaiting in tests; fixed sign-out bug (session now always cleared on sign-out regardless of server call result); 9 tests covering sign-in success/failure, sign-up with/without session, sign-up network failure, sign-out success/failure, session restore success/failure, isLoading state
- **SOP established**: docs updated per slice, committed together with code (not batched at session end)

- **Request/response logging slice**: Added request/success/error logging to BackendInventoryService (all paths in `send`), BackendSnapshotService (`fetchLatest` + `upsertLatest`), and BackendRecipeService (server error, decode failure, success)
- **Pre-existing bugs fixed** (surfaced by running the full test suite):
  - `InventoryStore.mergePantryItems`: name trimmed for empty-check but stored untrimmed — `" egg "` survived merge
  - `InventoryStore.mergeQuantityText`: early-return shortcut for identical strings ran before structured parsing — `"1 loaf" + "1 loaf" → "1 loaf"` instead of `"2 loaf"`; moved shortcut to fallback position
  - `InventoryStore.markPurchased`: if-branch double-merged pre-purchase snapshot with already-merged local item; fixed to upsert the already-computed local result
  - `RecipeViewModelTests`: sole non-async test in `@MainActor` class caused SIGABRT from Swift task deallocation ordering; fixed by making it `async`

- **Supabase schema slice**: Created 6 PostgreSQL tables (pantry_items, grocery_items, saved_recipes, cooked_meal_records, weekly_plan_meals, profiles) with RLS policies and indexes. Applied to production Supabase project. Migration saved to `supabase/migrations/20260423_initial_schema.sql`. DECISIONS.md updated with profileId design rationale and future household migration path.
- **iOS Supabase inventory integration**: Created `SupabaseInventoryService` implementing `InventorySyncingService` protocol; snake_case encoder/decoder configured on `SupabaseManager`; InventoryStore now syncs pantry/grocery directly to Supabase tables; `BackendInventoryService` no longer wired. Added `notAuthenticated` error case (silent fail, same as `missingBackendURL`). Also captured Phase E (data quality / fuzzy autocomplete) in PLANNING.md for next dedicated slice.
- **iOS Supabase snapshot integration**: Extracted `SnapshotSyncingService` protocol + shared `SnapshotSyncError`; created `SupabaseSnapshotService` (full backup as JSONB in `user_snapshots` table); `BackendSnapshotService` conforms to protocol (kept but unwired); `AppBackupCoordinator` now stores `any SnapshotSyncingService`; Cloudflare Worker is now OpenAI relay only.

### Commits
- `af192c1` Add AppLogger to SupabaseManager, CookedMealStore, recipe fallback, and Home recommendation
- `0210e3c` Add AuthStore tests via injected AuthServiceProtocol; always clear session on sign-out
- `8b77b5d` Add request/response logging to network services; fix InventoryStore merge bugs
- `1f0550a` Add Supabase schema v1: 6 tables with RLS, indexes, and migration file
- `db7ad03` Wire SupabaseInventoryService as the live inventory sync backend
- `029832f` Wire SupabaseSnapshotService as the live backup backend; Cloudflare Worker is now OpenAI relay only

### Carry Forward
- **Next slice**: Phase E — item entry data quality: fuzzy autocomplete on `KnownItemStore`, "did you mean?" post-entry suggestion
- **Later**: per-entity Supabase sync for saved_recipes, cooked_meal_records, weekly_plan_meals, profiles (currently backed by local UserDefaults only)
- **Later**: Android React Native app (`codex/react-native-android`)

---

## 2026-04-23 (session 4)

### Done
- Supabase auth foundation: sign in, sign up, session restore, sign out
- Root cause of sign-up failure: Bundle Local Secrets build phase only extracted 3 keys — SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY were never written to LocalSecrets.plist. Fixed the build phase script.
- AppConfig firstValid() hardened to reject any unexpanded $(VAR) build setting
- SPM lesson: packages must be added via Xcode UI (File → Add Package Dependencies), not hand-editing project.pbxproj
- Doc system enforced: all rules already existed, execution gap identified and called out

### Commits
- `fe946f1` Add Supabase auth: sign in, sign up, session restore, sign out

### Carry Forward
- Next slice: `codex/supabase-foundation` continues with database schema — PostgreSQL tables for pantry, grocery, saved recipes, cooked records, weekly plan, profile
- Replace BackendInventoryService (Cloudflare KV) with Supabase client
- Consider: create a new branch `codex/supabase-schema` for the data layer

---

## 2026-04-22 (session 3)

### Done
- Fixed worker purchase bug: `POST /v1/grocery/{id}/purchase` was using `crypto.randomUUID()` for the returned pantry item ID, causing duplicate pantry entries on first purchase of any ingredient
- Added nutrition layer to HomeView: today's calories + protein progress card, derived from `CookedMealStore.todayNutrition`
- Added "tonight's pick" to `HomeRecommendationEngine`: promotes highest-protein ready recipe when daily protein gap > 20g
- Added saved planning hub: macros on every recipe row, full macros section + goal-fit context in recipe detail view
- Added weekly meal plan: new "Plan" tab, up to 7 meals, deduplicated missing ingredients, one-tap grocery generation
- Merged `codex/nutrition-layer` → main via PR #3
- Updated PLANNING.md: Phase N all Built, Phase C weekly plan Built, Phase D rewritten for Android-first strategy
- Added DECISIONS.md: decision log for architecture and product choices
- Rewrote Phase D and user section of PLANNING.md for Android-first distribution
- Added DECISIONS.md and CLAUDE.md reference to it
- Doc system cleanup: retired SKILLS.md (content folded into CLAUDE.md), trimmed DECISIONS.md to product/architecture only, updated README.md for Android strategy and Supabase roadmap, added mandatory session-end rules to CLAUDE.md

### Commits (session 3)
- `7417bbc` Fix worker purchase endpoint creating pantry item with random UUID
- `e9f2983` Add nutrition-home: progress card, tonight's pick, and nutrition-aware engine
- `3ccb7ff` Add saved planning hub: macros, goal fit, and PLANNING.md Phase N update
- `6d27287` Add weekly meal plan: Plan tab, up to 7 meals, auto-generate grocery list
- `82c5cca` Add PlannedMeal, WeeklyPlanStore, WeeklyMealPlanView to Xcode project
- `19b8e16` Mark weekly meal plan Built in PLANNING.md
- `da74265` Merge PR #3: codex/nutrition-layer → main
- `2441f80` Clean up PLANNING.md: update stale Active/Built/Next labels
- `961892a` Rewrite PLANNING.md Phase D for Android-first distribution strategy
- `3298d4e` Add DECISIONS.md: decision log for architecture and product choices
- *(doc cleanup commit — pending)*

### Carry Forward
- Set up Supabase project (user action: create project at supabase.com, get URL + anon key)
- `codex/supabase-foundation`: Supabase auth (email/password) + database schema + iOS integration
- `codex/react-native-android`: Android app on same Supabase backend, Play Store target

---

## 2026-04-22 (continued)

### Done (session 2)
- Added `CLAUDE.md` — codebase guidance for future Claude sessions (build commands, architecture, conventions)
- Added `RESUME.md` — automated interrupt checkpoint system (Claude maintains it throughout sessions)
- Updated `WORKLOG.md` — documented interrupt/resume pattern
- Product design review: shifted product direction to nutrition-first (health-conscious use case)
- Locked roadmap: nutrition layer → nutrition home → saved hub → Supabase → Android

### Carry Forward
- Commit + PR this branch (`codex/home-recommendation-extraction`) — meta files only
- Branch `codex/nutrition-layer`: Recipe macros, NutritionGoals in UserProfile, OpenAI schema, Worker schema
- Branch `codex/nutrition-home`: Home progress card, tonight's pick, HomeRecommendationEngine nutrition awareness

---

## 2026-04-22

### Must Do
- Extract Home recommendation ranking from `HomeView` into a testable component
- Validate deterministic ordering with focused tests
- Commit this slice before starting the next one

### Watch
- Keep behavior unchanged in the first extraction pass
- Keep branch scope limited to recommendation selection logic + tests
- Avoid unrelated Xcode/project churn in this commit

### Done
- Added `HomeRecommendationEngine` as a pure ranking engine
- Kept `HomeView` rendering behavior and card copy unchanged while delegating selection to the engine
- Added `HomeRecommendationEngineTests` to lock ordering for:
  - expired items
  - favorite-ready recipes
  - staple-ready recipes
  - generic cook-again fallback
  - ready saved recipes vs near-miss
  - use-soon vs generic pantry cook
- Validation:
  - CLI compile gate passed (`build-for-testing`)
  - Xcode class run passed (`HomeRecommendationEngineTests`)

### Commit checkpoint
- Commit this slice now before moving to the next planned item.

### Carry Forward
- Next slice: `codex/saved-planning-hub-polish`

---

## 2026-04-10

### Must Do
- Phase A / product-safety: **Standalone recipe generation without client OpenAI key**
  - Land backend relay plan (Phase 1, Option A: static token auth) and map it into `PLANNING.md` as a Phase A **Next** item.
  - Define the backend contract to match iOS today (`POST /v1/recipes/generate` request + `Recipe` response).

### In Progress
- Hardened local secret handling (high severity risk mitigation):
  - Removed a hardcoded `OPENAI_API_KEY` from local scheme env config (and disabled it).
  - Updated the `Bundle Local Secrets` build phase so **Release/Archive builds do not embed `LocalSecrets.plist`**.
  - Updated local setup doc to reflect that `OPENAI_API_KEY` should be provided at runtime (Xcode scheme env var / CLI env), not bundled.

Files changed (currently uncommitted):
- `OPENAI_SETUP.md`
- `cookya.xcodeproj/project.pbxproj`

### Watch
- Git hygiene: keep the API-key hardening changes as a single focused commit; do not mix with backend work.
- Avoid `project.pbxproj` churn unrelated to the secret-hardening slice.
- Data safety: do not delete the app or erase simulators as “cleanup” steps (local data loss).

### Commit checkpoint
- Create a commit **now** for the secret-hardening slice (after one last `Cmd+B` / simulator build verification), before starting backend relay work.

### Learnings / Troubleshooting notes (keep for future agents)

#### Build + test (CLI / `xcodebuild`) gotchas
- **DerivedData permission errors in sandboxed environments**: if you see “Unable to write … `DerivedData/.../info.plist`” or log removal “Operation not permitted”, set a workspace-local derived data path.
  - Example: `xcodebuild ... -derivedDataPath "./.derivedData"`
- **SwiftUI `#Preview {}` macro failures**: if you see errors like “`PreviewsMacros.SwiftUIView` could not be found … swift-plugin-server produced malformed response”, replace `#Preview { ... }` blocks with classic `PreviewProvider` previews.
- **User script sandboxing can break build phases**: if your build fails in a script phase with `sandbox-exec: sandbox_apply: Operation not permitted`, disable user-script sandboxing in build settings.
  - Setting: `ENABLE_USER_SCRIPT_SANDBOXING = NO`
- **Codesign failures due to xattrs / Finder detritus**: if codesign fails with “resource fork, Finder information, or similar detritus not allowed”, it’s usually extended attributes on the built `.app`.
  - Quick fix: `xattr -cr <path-to-app-or-deriveddata>`
  - In restricted environments, also disabling simulator codesigning may be required:
    - `CODE_SIGNING_ALLOWED[sdk=iphonesimulator*] = NO`
    - `CODE_SIGNING_REQUIRED[sdk=iphonesimulator*] = NO`
- **`xcodebuild test` needs a concrete simulator**: “Any iOS Simulator Device” cannot run tests; `xcodebuild test` must target a specific device. If CoreSimulator is unhealthy or no runtimes are available, tests won’t run even if the project builds.

#### Xcode project file changes (`project.pbxproj`)
- **Patch context drifts easily**: `project.pbxproj` edits often fail because the file changes ordering/UUID blocks. Re-read the exact section you’re patching (PBXBuildFile/PBXFileReference/PBXGroup/PBXSourcesBuildPhase) and re-apply with fresh context.
- **New Swift file not found at compile time**: if a new file compiles in the editor but tests/build can’t see it, confirm it’s included in the `cookya` target “Sources” phase (and the file reference exists).

#### Node / backend local dev gotchas
- **`npm install` ran in wrong directory** (observed in this environment): if `npm` looks for `package.json` at repo root even when you tried to set a working directory, run with an explicit `cd`:
  - `cd backend && npm install`
- **Stray `package-lock.json` in repo root**: verify `npm` didn’t write lockfiles outside the intended folder; delete if created accidentally.

#### Cloudflare Workers / wrangler deployment gotchas
- **First deploy prompts**: `wrangler` may prompt to create the Worker and to pick a unique `workers.dev` subdomain. This is expected on first-time setup.
- **Transient TLS / DNS issues**: if `curl` hits TLS handshake failures right after deploy, it can be propagation/transient. Retrying after a short wait and verifying DNS/TLS usually resolves it.

#### Product/architecture note (why we did it this way)
- **Don’t ship an OpenAI key in the iOS client**: even Debug bundling is risky. Prefer a backend relay with server-side key; the app authenticates via a long random app token stored in Keychain.

### Done
- Backup import UX hardening:
  - Import now posts a single “backup imported” notification after applying the snapshot.
  - Stores reload from `UserDefaults` on notification so the UI refreshes immediately (no relaunch).
- Backend sync (inventory MVP):
  - Worker now supports pantry/grocery endpoints backed by KV.
  - iOS inventory sync authenticates with the Keychain token (Authorization bearer).
  - Sync refresh now merges remote + local and dedupes by normalized item name to avoid duplicates and prevent dropping local-only items during bootstrap.
  - Inventory sync cancellation is treated as non-failure (no error banner).
- Build stability hardening (to keep CLI builds usable):
  - Replaced SwiftUI `#Preview {}` macros with `PreviewProvider` where needed.
  - Adjusted project build settings to avoid script-sandbox and simulator codesign failures in restricted environments.
- Documentation:
  - Added skill-buildup guidance to `SKILLS.md`.
  - Added troubleshooting notes here for future sessions.

### Commits
- `11fa540` `Refresh app state after backup import`

### Carry Forward
- Phase A: start true durable backup (cloud or backend sync) so reinstall/device-loss is safe.

## 2026-04-04

### Must Do
- Finish the saved recipe planning hub
- Rewrite `PLANNING.md` around the current product reality
- Land lightweight app-state backup with validation
- Start Phase A persistence hardening after backup

### Nice to Have
- Clean up stray Xcode signing churn if it appears again
- Clarify the next recipe-first planning step after the hub lands
- If time permits, start recipe cache bounds work

### Watch
- Do not mix `project.pbxproj` signing-only noise into feature commits
- Keep the planning-doc rewrite separate from feature work
- Always target an explicit iOS simulator in CLI builds/tests

### Done
- Turned `Saved` into a planning hub with:
  - `Favorite Picks`
  - `Ready Now`
  - `Nearly Ready`
  - `Browse All Saved Recipes`
- Kept the full saved-library flow available underneath the hub
- Rewrote `PLANNING.md` as a reality-based roadmap for the current app
- Added a lightweight app-state backup layer that:
  - snapshots pantry, grocery, saved recipes, cooked history, profile, and known items
  - restores missing local state on launch
  - refreshes backup data automatically after local persistence changes
- Cleaned up profile persistence to use injected `UserDefaults` instead of hardcoded globals
- Hardened store persistence behavior by:
  - logging decode fallbacks explicitly
  - asserting on unexpected encode failures in DEBUG
  - validating persisted payload shape before decode
- Added regression coverage for persisted payload shape validation
- Verified the backup slice with:
  - unrestricted iOS simulator build
  - targeted backup regression tests
- Created a stable `iPhone 16 (26.4)` simulator so future CLI build/test runs can target a consistent destination
- Added `SKILLS.md` as a repo foundation document for:
  - data-safety rules
  - destructive-step guardrails
  - Xcode/build/test rules
  - git/workflow rules
- Started and completed the recipe cache bounds slice by:
  - adding a deterministic generated-recipe cache eviction policy
  - wiring `RecipeStore` to enforce a generated-recipe cache limit
  - replacing flaky timestamp/simulator store tests with pure policy tests
  - adding the policy file to the app target
- Fixed recurring Xcode build/signing friction by:
  - restricting Cookya targets to iOS/iPadOS instead of advertising Mac and visionOS support
  - setting the development team on `cookyaTests` and `cookyaUITests`
  - verifying `Cmd+B` / Xcode test success after the project configuration fix
- Captured the testing lesson that pure business logic should be extracted and tested directly instead of repeatedly driving simulator-hosted `ObservableObject` tests

### Commits
- `13687f6` `Turn saved recipes into a planning hub for ready and nearly-ready meals`
- `cb3d405` `Rewrite planning document around current product reality`
- `182d893` `Add daily worklog for planning and end-of-day wrapups`
- `e0af09a` `Add lightweight app-state backup and restore with regression tests`
- `1da3f68` `Harden store persistence failures and validate persisted payload shapes`
- `3d918be` `Add repo foundation guide for data safety and development workflow`
- `00375fb` `Bound generated recipe cache with deterministic eviction`
- `510f5bb` `Restrict Cookya targets to iOS and configure test signing`

### EOD status
- Branch: `codex/mvp-recipe-flow`
- Push status: pending for end of day

### Carry Forward
- Next likely product-safety slice: export/import backup before any reinstall-risk debugging
- Keep using this file at the start and end of each work session

---

## 2026-04-26 — Branch cleanup + intermittent networkError resolved

### Done
- Fixed stale PLANNING.md (auth/session marked Built; removed duplicate Next entry)
- Committed parked dirty files: .gitignore, CLAUDE.md (mobile rules), README.md, worker CORS fix
- Added `emitLocalSessionAsInitialSession: true` to SupabaseManager; silences Supabase SDK deprecation warning
- Manual validation confirmed: intermittent networkError on pull-to-refresh is resolved — was caused by auth session drift, now fixed by the auth/session reliability slice

### Branch state
All 4 iOS hardening priorities done and validated. Branch clean. No active interrupts.

### Carry Forward
- Decide next direction: Android/mobile work or remaining iOS items (HomeView refactor, broader test coverage)

---

## 2026-04-26 — Android mobile: first end-to-end web validation (M1)

### Done
- Created branch `codex/react-native-android`
- Committed all existing `mobile/` work to git (was untracked — safety checkpoint)
- Applied theme system to Pantry and Grocery screens (were using raw hex/magic numbers)
- Fixed `markPurchased` bug: pantry_items insert was missing `id` and `user_id` (same NOT NULL issue as iOS); removed Alert.alert confirmation wrapper (unreliable in Expo web)
- Added Profile tab with sign-out (👤); tab bar themed with design tokens
- Updated groceryStore tests: added mockGetUser setup + not-authenticated error path (29 tests total)
- Fixed pii-scan-staged.sh false positive: excluded @example.com/@test.com from email pattern

### Web validation (Expo web)
- Sign in ✓
- Pantry add ✓
- Recipe generation from pantry ✓ (all items used — intentional, matches iOS)
- Grocery add ✓, mark purchased ✓ (after fix)
- Profile tab + sign out ✓

### Pending
- Android device test (device not available today) — core loop identical to web; validate when available

### Carry Forward
- Android device test: sign in → pantry → recipe → grocery → sign out
- Next feature slice TBD after device validation

---

## 2026-04-26 — Android M2: category picker + error display (in progress)

### Goal
Fix category data correctness on Pantry and Grocery: both screens were hardcoding `category: 'pantry'` on every insert, sending meaningless data to Supabase and degrading recipe generation. Add error display so store failures are visible to users.

### Done locally (not yet validated or committed)
- `CategoryPicker` component: horizontal scrollable chip row, 9 categories matching iOS (vegetables, protein, grains, dairy, fruit, bakery, condiments, beverages, other), icon + label, selected state highlighted in primary colour
- Pantry and Grocery screens updated: CategoryPicker in add form, default category 'vegetables', error banner when `store.error` is non-null
- typecheck: clean; Jest: 29/29 passing

### Exact next step
1. Manual web test — reload Expo web, verify category picker appears and works in both Pantry and Grocery add forms
2. User confirms pass/fail
3. Update PLANNING.md M2 status to Built
4. Commit: CategoryPicker.tsx + pantry.tsx + grocery.tsx + WORKLOG + PLANNING + DECISIONS

### Branch state
- `codex/react-native-android`
- Last committed: `207b68e` (M1 session log)
- Uncommitted: `mobile/components/CategoryPicker.tsx`, `mobile/app/(tabs)/pantry.tsx`, `mobile/app/(tabs)/grocery.tsx`, `PLANNING.md`, `DECISIONS.md`, `WORKLOG.md`

---

## 2026-04-26 — Android parity sprint: M2–M8

### Context
User direction: no more slice-by-slice Android gates until device is available. Build to iOS parity in one pass; full device test session when device is ready.

### Done
- **M2**: CategoryPicker component (9 categories, horizontal chip row), error banners on Pantry and Grocery; delete confirmation Alerts removed (unreliable on web, unnecessary on native); typecheck + Jest clean
- **M3**: `savedRecipeStore` (fetch/save/toggleFavorite/delete, optimistic delete); Saved tab with plan integration and favorite toggle; Save Recipe button on RecipeCard
- **M4**: `profileStore` (fetch/upsert, user_id-scoped); Profile tab redesigned with name, vegetarian toggle, avoid-foods input; profile passed to `generateRecipe` so Worker receives dietary context
- **M5**: `cookedMealStore` (logCooked/fetchToday, tracks today's macros); "I Cooked This" button on RecipeCard
- **M6**: Nutrition progress bars on Home (calories + protein vs profile goals); only shown when profile has goals set
- **M7**: `weeklyPlanStore` (add/remove/clearAll, 7-meal cap); Plan tab with "Add All Ingredients to Grocery" one-tap action
- **M8**: Tonight's Pick recommendation card on Home (highest-protein saved recipe when protein gap > 20g)
- Types extended: `SavedRecipe`, `CookedMealRecord`, `UserProfile`, `NutritionGoals`, `WeeklyPlanMeal`
- `recipeService` updated to pass `profile.isVegetarian` and `profile.avoid_food_items` to Worker

### Validation pending
- Full device test session when Android device is available
- M9 (290-item catalog picker) and M10 (expiry dates) deferred to post-device-test

### Branch state
- `codex/react-native-android`
- Typecheck: clean | Jest: 29/29

---

## 2026-04-26 — Android parity: M9, M10, tests, plan fix

### Done
- **Plan screen fix**: unplanned recipes now have an "+ Add" button; plan respects 7-meal cap in UI
- **Tests — 4 new store test suites**: savedRecipeStore (8 tests), profileStore (4 tests), cookedMealStore (3 tests), weeklyPlanStore (5 tests); recipeService gets 2 new profile-context tests. Total: 52 tests (up from 29)
- **M9 — Item catalog**: 230-item `catalog.json` (all iOS items, mapped to Android categories including full Indian staples section); `ItemPicker` modal (search-first, shows top 30 on empty query, filters to 50 on input, custom item fallback); wired into Pantry and Grocery add forms via "Search catalog" button
- **M10 — Expiry dates**: quick-pick chip selector on Pantry add form (Today / 3 days / 1 week / 2 weeks / 1 month / No expiry); `pantryStore.addItem` extended to accept optional `expiryDate`; expiry label shown on each row (⚠️ Expired / Expires today / Expires in Xd); expired items dimmed

### All Android parity slices M1–M10: complete
### Typecheck: clean | Jest: 52/52
### Pending: full device test session when Android device available
