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
