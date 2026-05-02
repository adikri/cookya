# Cookya — Decision Log

Significant architectural, product, and workflow decisions made during development.
Format: date · decision · options considered · reason.

---

## 2026-04-22

### Android-first distribution strategy
**Decision:** Android (React Native, Play Store) is the primary public distribution target. iOS SwiftUI stays as Adi's personal daily driver and feature test bed only.
**Options considered:** iOS App Store (requires $99/yr Apple Developer), Android Play Store (free), web app.
**Reason:** No paid Apple Developer account planned. Play Store has no upfront cost. Goal is real user feedback and a production-grade portfolio piece. iOS app continues as the prototype/validation environment before features ship on Android.

### No Apple Sign In (for now)
**Decision:** Defer Apple Sign In. Use email/password + Google Sign In instead.
**Options considered:** Apple Sign In, Google Sign In, email/password, anonymous auth.
**Reason:** Apple Sign In requires a paid Apple Developer account for the server-side Service ID and private key Supabase needs. Not viable without the paid tier. Email + Google covers both platforms and the free tier fully.

### Supabase over Firebase and alternatives
**Decision:** Supabase as the shared backend for iOS and Android.
**Options considered:** Firebase, AWS Amplify, PocketBase, raw Node + Postgres.
**Reason:** PostgreSQL is the right model for Cookya's relational data (pantry, recipes, profiles). Supabase has official SDKs for both Swift and React Native. Low vendor lock-in — data lives in standard Postgres. Free tier is genuinely usable. Firebase would be the only real alternative but Firestore's document model is a worse fit and lock-in is higher.

### Weekly meal plan as a tab, not a Home section
**Decision:** Weekly meal plan lives in a dedicated "Plan" tab (4th tab in MainTabView).
**Options considered:** Section inside HomeView, card on Home, new tab.
**Reason:** The feature has enough surface area (list of meals, missing ingredients, add/remove flow) to warrant its own space. A Home section would have been too cramped and would have cluttered the command center.

### tonight's pick threshold at >20g remaining protein
**Decision:** `tonightsPick` recommendation only surfaces when remaining protein gap exceeds 20g.
**Options considered:** Various thresholds; always showing when any gap exists.
**Reason:** A trivial gap (e.g. 5g remaining) shouldn't change the recommendation. 20g is a meaningful amount that justifies overriding the default priority order. Threshold is injected via the engine, so it can be tuned.

### tonight's pick slots between cookAgain and savedRecipeReady
**Decision:** Priority order: expiredReview → favoriteReady → stapleReady → cookAgain → **tonightsPick** → savedRecipeReady → savedRecipeNearMiss → useSoon → cookFromPantry.
**Options considered:** Put it at the top; put it after all saved recipe cases; replace favoriteReady when nutrition-relevant.
**Reason:** Explicit user history (cook again, staples, favorites) is a stronger signal than nutrition optimization. But tonightsPick should beat generic "you have a saved recipe" since it provides a concrete reason. Favorites are not overridden because the user explicitly marked them.

### Saved planning hub: macros on rows, no nutrition-based resorting
**Decision:** Show protein on each saved recipe row. Show full macros + goal fit in the detail view. Do not re-sort saved recipes by nutrition fit.
**Options considered:** Nutrition-aware sorting; separate "high protein" section; macros only in detail.
**Reason:** Readiness-first ordering is the core value of the saved hub. Overriding it with nutrition would make the hub less predictable and defeat its primary purpose. Showing macros inline gives the user the information without changing the structure they rely on.

---

## 2026-05-02

### Parity-gated merge for codex/react-native-android (one-time exit move)
**Decision:** Defer merging `codex/react-native-android` into `main` until iOS and Android both pass smoke validation on the branch's current state. The merge happens as one milestone landing the Supabase migration + Android RN app + accumulated iOS features all at once.
**Scope:** This decision applies to the *current* branch only. It is **not** the ongoing development model — see the next entry for that.
**Options considered:** Merge now without validation; surgical commit-splitting to land Supabase first and Android later; one-shot validate-then-merge (chosen).
**Reason:** Validating Android requires iOS as the reference behavior, so device-testing has to happen on a branch where both are aligned. The branch is too entangled to split surgically — Supabase, RN app, and iOS feature commits are interleaved across 39 commits. Cleanest exit: validate once, land once, then never let a branch get this big again.

### Trunk-based development with parity-by-commit (ongoing model)
**Decision:** Going forward, every feature is a short-lived branch off `main`, merged within days via PR. Foundation work merges first; features stack on trunk, never on each other. For multi-platform features, parity is enforced **per-commit** — a PR ships every supported platform in the same commit (or paired commits in the same PR) — not via long-lived parity branches.
**Options considered:** GitFlow (develop / release / main branches); long-lived integration branches with periodic parity merges (status quo, what created `codex/react-native-android`); trunk-based with parity-by-commit (chosen).
**Reason:** Long-lived integration branches accumulate work that becomes harder to land. `codex/react-native-android` ended up holding Supabase migration + Android RN app + iOS feature parity + ongoing work, none of which finish independently — and it took weeks of stacking before the entanglement was visible. Trunk-based keeps `main` always shippable, branches cognitively light, and merge risk small. Parity-by-commit replaces parity-by-branch: instead of holding back `main` until a parity batch is ready, every PR is required to ship every platform. Operational rules captured in `CLAUDE.md` under "Branching workflow."

