# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## Resuming an interrupted session

Before reading anything else, check `RESUME.md` at the repo root. If it contains an active interrupt (anything other than the placeholder `(no active interrupt)`):
1. Read it fully — it captures the exact mid-session state from the last token-limit cutoff.
2. Confirm the branch and last commit match current git state (`git log --oneline -1`).
3. Pick up from **Exact next step** — do not re-derive context from scratch.

**During a session**, keep RESUME.md continuously up-to-date:
- Write it at the start of any non-trivial task (branch, what you're doing, first step).
- Rewrite it after each commit with the updated next step.
- Rewrite it before switching sub-tasks.
- This way, if tokens run out at any point, the file is already current — no manual intervention needed.

When the interrupted work is committed cleanly:
1. Append the RESUME.md content as a `### Session Resumed` block in the current day's WORKLOG.md entry.
2. Overwrite RESUME.md with `(no active interrupt)`.
3. Include both changes in the same commit that closes the work.

---

## Before starting any task

Read `PLANNING.md` first — it is the product and engineering source of truth. It defines what is Built, Active, Next, and Later, and contains the architecture conventions to follow.

Read `DECISIONS.md` for the reasoning behind significant past decisions. When a new significant **product or architecture** decision is made (not tooling/workflow — those go here in CLAUDE.md), add an entry to `DECISIONS.md` and commit it alongside the related code.

---

## Build and test commands

Use the repo scripts instead of typing raw `xcodebuild` flags:

```bash
# Simulator build
./scripts/build-sim.sh

# Simulator tests (full suite — boots simulator if needed)
./scripts/test-sim.sh

# Fast re-run without recompiling (simulator must already be Booted)
./scripts/test-quick.sh

# Device build (requires COOKYA_DEVICE_ID)
COOKYA_DEVICE_ID="<your-device-id>" ./scripts/build-device.sh
```

Always use an explicit iOS simulator destination. Bare `xcodebuild build` may resolve to `My Mac` and produce spurious signing errors.

> **CLI test runs stall in this environment.** Do not invoke `xcodebuild test`, `test-sim.sh`, or `test-quick.sh` from the terminal. Instead, after writing tests provide the user with:
> 1. Which test class(es) to run in Xcode
> 2. What passing looks like
> Use `Product → Test` or the diamond gutter icon in Xcode.

Verify Xcode toolchain: `xcode-select -p` must print `/Applications/Xcode.app/Contents/Developer`. Fix with `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

Enable the PII/secrets pre-commit hook once per clone:
```bash
git config core.hooksPath .githooks
```

### Worker backend (Cloudflare)
```bash
cd worker && npx wrangler dev   # local dev
cd worker && npx wrangler deploy
```

### Local Express relay (dev only)
```bash
cd backend && npm install && npm run dev
```

---

## Architecture

### Three-component layout

| Component | Purpose |
|-----------|---------|
| `cookya/` | iOS SwiftUI app (the product) |
| `worker/` | Cloudflare Worker — recipe relay + KV inventory + snapshot backup (recommended production backend) |
| `backend/` | Node/Express relay — local dev alternative, same API surface |

### iOS app structure

All stores are initialized in `cookyaApp.swift` with an injected `UserDefaults` instance and passed into the view hierarchy as `@EnvironmentObject`. The root switches between `ProfileOnboardingView` and `MainTabView` based on `profileStore.hasCompletedOnboarding`.

**Stores** (`Services/`) — own persisted state, `@Published private(set)` properties, injected `UserDefaults`:
- `InventoryStore` — pantry and grocery items
- `RecipeStore` — generated recipe cache and saved recipes
- `CookedMealStore` — cooked history
- `KnownItemStore` — pantry/grocery memory for autocomplete
- `ProfileStore` — user dietary profile
- `BackendSyncStatusStore` — last-sync metadata

**Services** (`Services/`) — protocol-first, no direct store dependencies:
- `RecipeGeneratingService` / `OpenAIRecipeService` / `BackendRecipeService` — LLM recipe generation
- `BackendInventoryService` / `BackendSnapshotService` — Cloudflare Worker sync
- `InventorySyncingService` — orchestrates inventory push/pull
- `AppBackupCoordinator` — export/import and cloud snapshot restore on launch

**ViewModels** (`ViewModels/`) — currently only `RecipeViewModel`. Other views still hold some logic directly (acknowledged technical debt; extract incrementally, not wholesale).

**Views** (`Views/`) — SwiftUI views. `HomeView` is the kitchen command center; it still contains recommendation logic that is being incrementally extracted (see `HomeRecommendationEngine`).

### Data flow

```
UserDefaults ──▶ Stores ──▶ @EnvironmentObject ──▶ Views / ViewModels
                                                         │
                               Protocol-backed Services ◀┘
                                         │
                              Cloudflare Worker / OpenAI API
```

`AppBackupCoordinator` coordinates both local backup (on `scenePhase` change) and backend snapshot restore (async on launch).

### Worker (Cloudflare)

Single `worker/src/index.ts`. Routes:
- `POST /api/recipe/generate` — auth via `COOKYA_APP_TOKEN` header, proxies to OpenAI
- KV inventory and snapshot endpoints — partitioned by token scope

Env vars set via `wrangler secret put`: `OPENAI_API_KEY`, `COOKYA_APP_TOKEN`. KV namespace bound as `COOKYA_KV`.

---

## Architecture conventions (from PLANNING.md)

- New services: **protocol first, implementation second**
- New ViewModels: `@MainActor final class`, `ObservableObject`, dependencies via `init`
- Use `AppLogger` for significant actions, decisions, and failures
- Store decode fallbacks must be logged explicitly; use `assertionFailure` in DEBUG for impossible encode failures
- All LLM calls go through protocol-backed services with structured output parsing

### SwiftUI `Section` rule — compiler-sensitive

Always use the explicit trailing-closure form:
```swift
Section {
    ...
} header: {
    Text("...")
}
```
Never use `Section("Header") { ... }` — this triggers compiler issues in this project.

### Do not
- Add third-party dependencies without discussion
- Put new decision logic into Views when a ViewModel/service boundary is warranted
- Change service protocols without updating all conformances and tests
- Mix Xcode signing/project churn into feature commits

---

## Testing

Tests live in `cookyaTests/`. Current coverage: recipe cache policy, home recommendation engine, backup/import, persistence payload validation, recipe ViewModel.

Prefer **deterministic unit seams**: pure inputs, injected values, no real clock dependency. Avoid driving pure business logic through `@MainActor ObservableObject` lifecycle when a plain helper suffices.

If `xcodebuild test` stalls after a clean compile, suspect simulator/XCTest runtime — retry on another simulator destination before diagnosing app code.

---

## Data safety

Deleting the app from device or erasing a simulator **destroys all local app data**. Before any such debugging step, confirm whether data is backed up and warn the user explicitly.

Operations that are safe for data: clean build folder, delete DerivedData, rebuild, restart Xcode/Simulator.

---

## Session end — mandatory

At the end of every working session, before stopping:

1. **Update `WORKLOG.md`** — add an entry for the session: what was done, all commits created, carry-forward items. This is not optional.
2. **Update `README.md`** — if the product description, architecture, or repository layout changed during the session, update it before closing.

---

## Engineering habits

**Classify failures fast (< 2 min):**
- Compile error → compiler points to file/line with type/symbol issue → fix the code
- Tooling/environment → simulator, codesign, sandbox, DerivedData permissions → fix the environment

**Smallest failing command:** keep a minimal repro that proves the bug, use it to verify the fix.

**Simulator stall recovery:**
```bash
pkill -f xcodebuild        # kill stale processes
xcrun simctl shutdown all  # reset simulator state
./scripts/build-sim.sh     # clean start
```

**project.pbxproj is a config database, not source code.** When a Swift type is "missing", check target membership / Sources build phase before suspecting the Swift code itself. Always edit it directly when adding new files — never ask the user to add files in Xcode manually.

**Secrets:** never ship API keys in the iOS client. Use the backend relay with server-side keys and a revocable app token in Keychain.

**Commit shape:** each commit tells one story. Don't mix Xcode signing churn with feature logic.
