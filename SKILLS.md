# Cookya Skills and Build Foundation

Use this file as a practical foundation for how we build and debug Cookya.

It exists to capture learnings that should not be relearned the hard way.

---

## 1. Core Working Rules

### One active task at a time
- keep one item `Active`
- keep other ideas `Pending` or `Parked`
- commit validated work before switching contexts

### Commit hygiene
- commit at clean checkpoints
- commit messages must be complete, specific, and honest
- do not bundle unrelated Xcode or signing churn into feature commits

### Push cadence
- push to GitHub at end of day after the worklog is updated

### Daily workflow
- start from `WORKLOG.md`
- define `Must Do`, `Nice to Have`, and `Watch`
- end the day with:
  - `Done`
  - `Commits`
  - `Carry Forward`

---

## 2. Data Safety Rules

This is a critical foundation rule:

**Before any destructive troubleshooting step, explicitly discuss what happens to app data.**

That includes steps like:
- deleting the app from a device
- erasing a simulator
- resetting local app storage
- changing persistence locations
- clearing state to debug onboarding or restore flows

### Current Cookya data durability reality

As of now:
- local app state lives in the app sandbox
- the current backup slice improves local durability and state restoration
- it does **not** yet guarantee reinstall-safe recovery

### What survives vs. what does not

Usually safe for data:
- `Product > Clean Build Folder`
- deleting DerivedData
- rebuilding
- restarting Xcode
- restarting Simulator

Destructive to local app data:
- deleting the app from device
- deleting the app from simulator
- erasing a simulator

### Required rule before destructive steps

Before suggesting a destructive step, we must say:
1. whether current app data will survive
2. whether we have a backup/export first
3. what the user should do if preserving data matters

### Current learning

We learned this the hard way:
- deleting the app from the phone fixed a runtime issue
- but also removed all local app data

That must not be treated as a casual debugging step again.

---

## 3. Build and Test Environment Rules

### Always use full Xcode, not just Command Line Tools

Expected:
- `xcode-select -p` -> `/Applications/Xcode.app/Contents/Developer`

If not:
```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Always use an explicit iOS destination in CLI builds/tests

Do not rely on bare `xcodebuild build` or `xcodebuild test`.

Reason:
- otherwise Xcode may choose `My Mac`
- that can trigger unrelated signing issues

Preferred pattern:
```bash
xcodebuild -project cookya.xcodeproj \
  -scheme cookya \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

### Stable simulator note

We created:
- `iPhone 16 (26.4)`

But simulator runtime behavior can still vary.
If one simulator hangs during tests, retry on another known-good iOS simulator before assuming app-code failure.

### Distinguish build failure from simulator/runtime failure

Examples:
- compile errors: app code / project wiring
- `My Mac` signing errors: destination/tooling issue
- hung `xcodebuild test` after compile: often simulator/XCTest runtime issue
- random Apple process crash prompts: often simulator/system noise, not app failure

---

## 4. Xcode and SwiftUI Repo Rules

### SwiftUI `Section` rule

This repo/compiler setup is sensitive to shorthand section syntax.

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
- avoid interactive controls directly inside section headers unless already proven safe here

### Xcode issue navigator can be stale

If the sidebar shows compile errors that do not match current code:
- trust a fresh build over stale index state
- clean build folder
- rebuild
- only then act on the errors

---

## 5. Testing Rules

### When changing core logic
Prefer adding or updating regression tests for:
- persistence
- inventory trust
- recipe memory
- merge behavior
- restore behavior

### How to run tests in Xcode

Running a test file is not always done from right-clicking the file in the Project navigator.

Preferred ways:
1. open the test file and click the diamond icon next to:
   - the test class
   - or an individual test method
2. use the Test navigator in Xcode
3. use `Product > Test` for the full scheme

If you do not see a run option from the folder pane, that does **not** necessarily mean the file is not in the test target.

### CLI test rule

If `xcodebuild test` stalls:
- distinguish compile success from runtime hang
- inspect simulator state
- retry on another explicit iOS simulator destination
- do not assume app-code failure until runtime behavior is separated from compile behavior
- do not stack repeated CLI test runs; stop or inspect the existing runner first

### Prefer deterministic unit seams

When testing pure business rules, avoid driving them through heavy app-runtime objects if the logic can be extracted.

Prefer:
- pure helpers / policy objects
- explicit inputs
- deterministic timestamps or injected values

Avoid when possible:
- tests that depend on real clock timing
- tests that require `@MainActor ObservableObject` lifecycle just to verify pure logic
- repeated simulator-hosted XCTest retries for logic that can be tested without UI/runtime state

Learning:
- recipe cache eviction should be validated through a deterministic cache policy, not by sleeping between `RecipeStore` calls and hoping timestamps order correctly

---

## 6. Persistence and Backup Rules

### Current rule

If persistence fails:
- do not fail silently where we can log it
- log decode fallbacks explicitly
- use `assertionFailure` in DEBUG for unexpected encode failures

### Current product gap

Lightweight local backup is not enough for reinstall safety.

We still need:
1. export/import backup
2. true durable backup outside the app sandbox

---

## 7. Communication Rules

### Environment blockers

If a problem is environment-level rather than app-code-level:
- say so immediately
- explain the exact cause
- tell the user exactly what they can do to help

### Destructive steps

If suggesting a destructive step:
- pause
- explain the consequence
- call out data loss risk explicitly

### Decision framing

When there are multiple viable paths:
- recommend one clearly
- explain tradeoffs briefly
- avoid making the user guess consequences

---

## 8. Current Foundational Learnings

## 9. Skill Buildup (how to get better while shipping)

These are intentional habits to build. They pay off in speed, quality, and confidence.

### Triage muscle: classify failures fast
- **Code error**: compiler points to a file/line with a concrete type/symbol issue.
- **Tooling / environment**: simulator/CoreSimulator, codesign, sandbox, DerivedData permissions, plugin/macro server failures.

Rule: spend **< 2 minutes** classifying before “trying random fixes”.

### Repro muscle: smallest failing command
Keep a minimal command that proves the bug exists, and use it to verify the fix.

Examples:
- **Build (workspace-local DerivedData)**:
```bash
xcodebuild clean build -scheme cookya \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "./.derivedData"
```
- **Tests (focused)**:
```bash
xcodebuild test -scheme cookya \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
  -derivedDataPath "./.derivedData" \
  -only-testing:cookyaTests/SomeTestClass
```

### Xcode project hygiene
- Treat `cookya.xcodeproj/project.pbxproj` as a **generated config database**, not “source code”.
- When a new Swift type is “missing”, suspect **target membership / Sources build phase** before suspecting Swift itself.
- Prefer tight, reviewable project-file edits; expect context drift and re-read before patching.

### Secrets muscle: assume the client is hostile
- Do not ship API keys in the iOS client (not even “just in Debug” unless you fully understand the blast radius).
- Prefer a backend relay with server-side keys and a revocable app token stored in Keychain.

### Persistence UX muscle: “apply” is not the feature
For backup/import/export flows:
- The feature isn’t complete until the app **reacts** (stores reload + UI refresh) without requiring a relaunch.
- Prefer one coordination primitive (e.g. a single notification) over ad-hoc refresh calls spread across views.

### Git muscle: commit in reversible slices
- Each commit should tell one story and be safe to revert.
- Don’t mix “Xcode churn” + feature logic unless unavoidable; if unavoidable, explain why in the commit message.

### Learning: data-loss implications must be surfaced before troubleshooting
- deleting the app removes local app state
- local backup inside the app sandbox is not reinstall-safe
- destructive debugging steps need explicit warning first

### Learning: explicit simulator destinations prevent misleading Mac signing failures
- CLI builds/tests must target iOS explicitly

### Learning: simulator/XCTest runtime problems can look like app problems
- a passing build plus hanging test runner usually means simulator/runtime needs separate diagnosis

### Learning: clean git history matters to the product story
- keep feature commits, docs commits, and tooling churn separate whenever possible
