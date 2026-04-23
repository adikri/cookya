# Cookya — Decision Log

Significant architectural, product, and workflow decisions made during development.
Format: date · decision · options considered · reason.

---

## 2026-04-23

### Supabase schema: local profileId preserved as PK; user_id as RLS anchor

**Decision:** `profiles.id` = local iOS `UserProfile.id` (locally-generated UUID). Every table carries `user_id UUID REFERENCES auth.users(id)` as the RLS anchor. `profiles.user_id` has a UNIQUE constraint — 1:1 with the auth user.

**Options considered:**
- Use `auth.uid()` as the profile primary key now — cleaner long-term but requires touching `SavedRecipe.profileId` and `CookedMealRecord.profileId` iOS models immediately.
- Preserve local `id` as PK, add `user_id` separately — no model churn, fully safe for single-user phase.

**Reason:** The app is single-user for now (one Supabase auth user = one profile). RLS via `user_id` already scopes all data correctly. Preserving the local UUID as PK keeps this slice self-contained.

**Migration path when household accounts ship:**
1. Make `profiles.user_id` the primary key (drop separate `id` or keep as alias)
2. Update `saved_recipes.profile_id` and `cooked_meal_records.profile_id` to reference `auth.users(id)`
3. Update iOS models: `SavedRecipe.profileId` and `CookedMealRecord.profileId` populated from `auth.uid()` instead of local profile UUID
4. Extend RLS policies with a `household_members` join table

---

### Which keys are safe to bundle in the app binary

**Decision:** Bundle `SUPABASE_PUBLISHABLE_KEY` and `COOKYA_BACKEND_BASE_URL`. Never bundle `OPENAI_API_KEY`. Store `COOKYA_APP_TOKEN` in Keychain only.

**Options considered:** Bundle all non-secret config; bundle nothing and fetch at runtime; apply same rule to all keys.

**Reason:**
- `OPENAI_API_KEY` bills money if leaked — must never leave the server. Goes through the Cloudflare Worker relay permanently.
- `COOKYA_APP_TOKEN` authenticates the app to the Worker — user enters it at runtime, stored in Keychain. Not bundled.
- `SUPABASE_PUBLISHABLE_KEY` is intentionally public (equivalent to Firebase's web API key). Safe to bundle *because* Supabase's Row Level Security (RLS) is the real protection layer — the key alone grants nothing beyond what RLS policies allow.
- `COOKYA_BACKEND_BASE_URL` is a URL with no auth value.

**Critical prerequisite:** The Supabase publishable key being bundled is only safe once RLS policies are in place on every table. Until then, the anon key gives unrestricted access to all data. RLS setup is a required part of `codex/supabase-schema`, not an optional follow-up.

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

