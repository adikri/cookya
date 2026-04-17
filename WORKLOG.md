# Cookya Worklog

Use this file to keep daily planning and end-of-day progress visible.

## Daily workflow

### Start of day
- Fill in `Must Do`, `Nice to Have`, and `Watch`
- Keep the list short enough that we can realistically finish it
- Pick one slice only for the day and note the branch that owns it

### During the day
- Move items between `In Progress`, `Done`, `Blocked`, and `Carry Forward`
- Commit validated work at clean checkpoints instead of batching unrelated changes
- If switching between Codex and Cursor, either:
  - commit the validated slice first
  - or write the exact in-progress state here before switching

### End of day
- Record what actually got done
- List commits created that day
- Note what carries into the next session
- Push to GitHub after the wrap-up

### Branch rule
- `main` is the stable integration branch
- use one short-lived branch per focused slice
- branch names should describe the actual work being done
- do not keep extending an old branch once the scope has drifted

### Daily slice template
- Branch:
- Slice type: architecture cleanup / hardening-test / UI-product / backend-contract
- Handoff status: validated / in progress / blocked

---

## 2026-04-17

### Must Do
- Workflow re-baseline:
  - refresh `PLANNING.md` so backend relay / backend snapshot sync are represented as built or active instead of future work
  - formalize branch hygiene and one-slice-per-day rules in repo guidance
  - make `WORKLOG.md` the default handoff file between Codex and Cursor sessions

### Nice to Have
- Record the next 3 concrete slice branches in `PLANNING.md` ordering:
  - backend sync hardening
  - Home recommendation extraction
  - saved planning hub polish

### Watch
- Keep this slice doc/process only
- Do not mix backend or UI code changes into the workflow re-baseline branch
- Commit this slice before moving on to reliability work

### Branch
- `codex/workflow-rebaseline`

### Slice type
- hardening-test

### Handoff status
- validated

### Done
- Re-baselined `PLANNING.md` to match current repo reality:
  - backend recipe relay is built
  - backend snapshot backup/restore is active
  - backend inventory sync hardening is now the next reliability slice
- Added explicit branch hygiene and one-slice-per-day rules to repo guidance
- Turned `WORKLOG.md` into the default Codex/Cursor handoff file for uncommitted work

### Commit checkpoint
- Create one focused commit for the workflow re-baseline slice before moving to backend reliability hardening

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
