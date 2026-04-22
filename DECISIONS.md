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

### Worker purchase endpoint: use grocery item ID for new pantry entry
**Decision:** `POST /v1/grocery/{id}/purchase` returns a pantry item with `id: id` (the grocery item's ID), not `id: crypto.randomUUID()`.
**Options considered:** Keep random UUID and fix client-side dedup; use grocery item's ID.
**Reason:** The iOS client inserts a local placeholder with `id = groceryItem.id` before the API call. When the backend returned a different UUID, `replacePantryItemLocally` couldn't find the placeholder and appended a second entry — a duplicate. Using the same ID makes the replace work correctly without any client changes.

### CLI test runs: always use Xcode manually
**Decision:** Never invoke `xcodebuild test`, `test-sim.sh`, or `test-quick.sh` from the terminal.
**Options considered:** CLI test runs, Xcode manual runs.
**Reason:** CLI test invocations stall repeatedly in this environment with no output. After writing tests, provide the user with the test class name and expected results; they run it in Xcode via the gutter diamond or Product → Test.

### New Swift files: always edit project.pbxproj directly
**Decision:** When creating new `.swift` files, immediately edit `project.pbxproj` in the same step — never ask the user to add files in Xcode manually.
**Options considered:** Ask user to add via Xcode UI, edit project file directly.
**Reason:** Asking the user to do things that can be done via code wastes their time. The project file edits (PBXBuildFile, PBXFileReference, group children, Sources build phase) are mechanical and reliable when done carefully.
