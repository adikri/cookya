# Cookya — Competitive Analysis

_Last updated: 2026-05-01. Refresh when a major competitor ships a category-shifting feature, when Cookya's positioning changes, or at least every 6 months._

This doc captures (1) the current state of the cooking / pantry / meal-planning app landscape, (2) where Cookya sits in it, (3) UI/UX references worth studying for the Android React Native rewrite, and (4) strategic moves that follow from the analysis. It is reference material — not part of the operational 5-doc system. `PLANNING.md` owns roadmap; this doc owns market context.

---

## Table of contents

1. [Snapshot — comparison matrix](#1-snapshot--comparison-matrix)
2. [Competitor profiles](#2-competitor-profiles)
3. [Where Cookya stands](#3-where-cookya-stands)
4. [UI/UX reference — patterns and anti-patterns](#4-uiux-reference--patterns-and-anti-patterns)
5. [Patterns Cookya should study for the Android rewrite](#5-patterns-cookya-should-study-for-the-android-rewrite)
6. [Strategic moves](#6-strategic-moves)
7. [Sources](#7-sources)

---

## 1. Snapshot — comparison matrix

Legend: ● strong • partial ○ none

| App | Pantry+expiry | Decrement on cook | AI recipe gen | Meal plan | Macros + goal-driven | Household | Pantry-first reco |
|---|---|---|---|---|---|---|---|
| **Cookya** | ● | ● | ● | ● | ● | (planned via Supabase) | ● |
| SuperCook | ○ | ○ | • | ○ | • | ○ | ● |
| Plant Jammer | ○ | ○ | ● | ○ | ○ | ○ | • |
| DishGen / ChefGPT | ○ | ○ | ● | • (Premium) | • (MacrosChef) | ○ | ○ |
| Samsung Food | • | • (manual) | ● | ● | ● | ● (Samsung-locked) | ○ |
| Mealime | ○ | ○ | ○ | ● | • | • | ○ |
| Paprika | ● (deepened Jan 2026) | ○ | ○ | ● | ○ (manual) | ● | ○ |
| AnyList | ○ | ○ | ○ | • | ○ | ● (best-in-class) | ○ |
| Eat This Much | • (suppress-from-list only) | ○ | ○ | ● | ● (macro-target plan gen) | ○ | ○ |
| PlateJoy | shut down 2025 | | | | | | |
| MyFitnessPal | ○ | ○ | ○ | ● (Premium+) | ● | ○ | ○ |
| Cronometer | ○ | ○ | ○ | ○ | ● (Oracle nutrient gap) | ○ | ○ |

---

## 2. Competitor profiles

### Direct competitors — pantry-first / AI recipe

#### SuperCook
- **Platforms + pricing.** iOS, Android, web. Free with a "daily free recipe allowance" after a 48-hour premium trial; premium tier exists but is not the gating wall.
- **Core value prop.** "What can I cook with what I already have?" — the longest-running pantry-first recipe search engine, indexing ~11M recipes from ~18,000 sites.
- **Pantry handling.** Deep on breadth (2,000+ ingredient catalog, voice-add, photo-scan-the-fridge in 2026), shallow on lifecycle: no expiry-bucket model, no decrement-on-cook, no duplicate merge with quantity reconciliation. Pantry is a checklist, not an inventory.
- **Recipe model.** Curated/scraped DB plus an AI overlay that ranks and adapts. Not generative-first.
- **Meal planning.** None to speak of — single-recipe discovery flow.
- **Nutrition.** Macros and calories on suggested recipes; a 2026 "snap a meal photo for nutrition" feature exists. No goal-driven recommendation.
- **Household.** Single-account; no shared pantry.
- **Strengths.** Best-in-class ingredient → recipe matching at scale; lowest-friction onboarding for the pantry use case.
- **Gaps vs Cookya.** No expiry tracking, no cooked-decrement, no meal plan, no nutrition goals, no household.

#### Plant Jammer
- **Platforms + pricing.** iOS, Android (last build 10.6.9, March 2026). Free with optional premium.
- **Core value prop.** Use what's in your fridge to "jam" plant-forward recipes by balancing flavor axes (sour, sweet, umami, salt, oil, crunch, bitter, spicy).
- **Pantry handling.** Light — fridge inputs are ephemeral per-session, not a persistent inventory with quantities/expiry. No decrement.
- **Recipe model.** AI-generative, trained on ~3M recipes, with strong ingredient-pairing logic. Plant-forward bias.
- **Meal planning.** None.
- **Nutrition.** Minimal; not a tracking app.
- **Household.** None.
- **Strengths.** Distinctive flavor-balancing UX; food-waste positioning; well-funded (€4M raise).
- **Gaps vs Cookya.** Not really an inventory app; missing meal plan, nutrition goals, decrement.

#### DishGen / ChefGPT (leading AI-recipe apps in 2026)
- **Platforms + pricing.** iOS + web. Free with monthly recipe credits; Premium ~$7.99/mo; Pro ~$15.99/mo.
- **Core value prop.** Chat-style "give me a recipe from these ingredients / this craving" — fastest path to a usable recipe (<60s).
- **Pantry handling.** Effectively none — you paste/type ingredients per generation. No state.
- **Recipe model.** Pure generative AI. 1M+ generated recipes browsable as a discovery layer. Recipe modification via chat is the killer interaction.
- **Meal planning.** Yes on Premium — AI-generated multi-day plans, but not pantry-anchored.
- **Nutrition.** Macros surfaced; ChefGPT specifically has "MacrosChef" — macro-targeted ingredient-constrained generation, the one feature that overlaps directly with Cookya's protein-prioritized recommendation.
- **Household.** None.
- **Strengths.** Speed, conversational refinement, lowest friction for "what should I cook tonight."
- **Gaps vs Cookya.** No persistent pantry, no expiry, no decrement, no household, no grocery-purchase-confirmation loop.

#### Samsung Food (formerly Whisk)
- **Platforms + pricing.** iOS, Android, web, Samsung appliances. Freemium; Food+ at $6.99/mo or $59.99/yr. Vision AI features gated to Galaxy hardware.
- **Core value prop.** End-to-end: recipe import from any URL → AI meal plan → grocery list → smart-oven cook mode.
- **Pantry handling.** Has a "Food List" tracking ingredients across fridge/freezer/pantry, with photo-add, automated suggestions, and a "remove items used while cooking" flow that does decrement. Expiry tracking on the Family Hub fridge side; in-app expiry support is shallower and users have reported reliability issues. No documented duplicate-merge logic.
- **Recipe model.** Massive curated/imported DB (Whisk legacy) + AI personalization + AI recipe creation. Strongest recipe library of the bunch.
- **Meal planning.** AI weekly plans personalized to diet/goals — mature.
- **Nutrition.** Detailed breakdowns; Vision AI calorie estimation from photos (Galaxy only).
- **Household.** Multi-user via Samsung account; lists shareable.
- **Strengths.** Most feature-complete competitor on paper — recipe + plan + pantry + grocery + nutrition + appliance integration.
- **Gaps vs Cookya.** Not pantry-first in the recommendation loop (recipes aren't sorted by what's expiring); no expiry-bucket UX (Use Soon / Available / Expired) as a first-class organizing principle; no protein-gap-driven "tonight's pick"; expiry data quality is reportedly fragile.

### Meal planning / grocery / household

#### Mealime
- **Platforms + pricing.** iOS, Android. Free tier; Pro $5.99/mo (raised in 2026 from $2.99).
- **Core value prop.** Weekday meal plans from a 1,200-recipe curated library with auto-generated, aisle-sorted grocery lists. 30-min recipes.
- **Pantry handling.** None — assumes you start from grocery list each week.
- **Recipe model.** Curated, hand-tested DB. Not AI generative.
- **Meal planning.** Strong — its core competence. Not pantry-aware.
- **Nutrition.** Pro tier shows calories/macros/micros; calorie filter on plans. No goal-driven recommendation.
- **Household.** Limited; list sharing exists.
- **Strengths.** Quality curation, aisle-sorted lists, grocery delivery integrations (Instacart, Kroger, Walmart, Amazon Fresh).
- **Gaps vs Cookya.** No pantry, no AI generation, no decrement loop, no protein-gap intelligence.

#### Paprika Recipe Manager
- **Platforms + pricing.** iOS, macOS, Android, Windows. Paid one-time $29.99 per platform — refuses subscriptions, which is now a differentiator.
- **Core value prop.** Personal recipe library + meal planner + grocery list with first-class web-clip import. Power-user tool.
- **Pantry handling.** Genuine pantry feature: track ingredients, quantities, and expiry dates; grocery-list generation excludes items already in pantry. The Jan 2026 v3.8.4 update specifically deepened pantry tracking. Closest direct overlap with Cookya's pantry depth among non-AI apps.
- **Recipe model.** User-imported and user-typed; no AI generation, no built-in recipe DB.
- **Meal planning.** Daily/weekly/monthly calendars. Mature.
- **Nutrition.** Manual; no auto-calc from biometrics, no goal layer.
- **Household.** Cloud sync across devices; family sharing supported.
- **Strengths.** No-subscription pricing, durable, polished, expiry support, cross-platform parity.
- **Gaps vs Cookya.** No AI recipe generation; nutrition is BYO; no protein-gap recommendation; no near-miss "you're 1 ingredient away" suggestions.

#### AnyList
- **Platforms + pricing.** iOS (App Store + Apple Watch), Android, web. Free for lists; AnyList Complete $9.99/yr individual or $14.99/yr household.
- **Core value prop.** The shared grocery list, done right — real-time sync across household members, automatic aisle sorting, duplicate combining.
- **Pantry handling.** None as a managed inventory; pantry is just another list.
- **Recipe model.** Web import, manual entry. Recipe timers in v3.0.
- **Meal planning.** Calendar-based, decent.
- **Nutrition.** None.
- **Household.** Strongest in the category — built around it.
- **Strengths.** Real-time sharing, store/aisle intelligence, budget tracking, affordable.
- **Gaps vs Cookya.** No real pantry inventory, no AI, no nutrition, no decrement, no expiry.

#### Eat This Much
- **Platforms + pricing.** iOS, Android, web. Free for single-day plans; Premium $5/mo annual ($60/yr) or $15/mo monthly.
- **Core value prop.** Set calories + macros + diet → app generates an automatic meal plan that hits the targets.
- **Pantry handling.** "Virtual pantry" used to subtract owned items from the grocery list. Quantities yes; expiry buckets and decrement-on-cook not surfaced as features.
- **Recipe model.** Curated DB with substitution; no generative AI as primary mode.
- **Meal planning.** Algorithm-driven, macro-first — its signature.
- **Nutrition.** Strongest among the meal-planners — macro-targeted plan generation is the core loop. Most direct conceptual overlap with Cookya's nutrition layer.
- **Household.** Individual focus; coach/Pro tier for trainers.
- **Strengths.** Macro-target meal generation, Instacart/Amazon Fresh delivery, cheap annual price.
- **Gaps vs Cookya.** Pantry is a list-suppressor, not a living inventory; no expiry buckets; no AI generative recipes; no protein-gap nudge inside the recommendation surface.

#### PlateJoy
Shut down in 2025 (acquired by RVO Health, removed from Play Store March 2025; domain dead in 2026). Still listed in many roundups but no longer a live competitor. Worth noting because it ceded the "personalized meal plan with digital pantry" niche — there's an opening here.

### Nutrition-adjacent — context, not direct competitors

#### MyFitnessPal
- **Platforms + pricing.** iOS, Android, web. Free; Premium $79.99/yr; Premium+ $99.99/yr. Barcode scanner moved behind Premium in 2022.
- **Core value prop.** The default food-log/calorie-counter, with the largest food DB (~18M items).
- **Relevant to Cookya.** Premium+ added a Meal Plan Builder, Meal Prep Mode, and Auto Grocery Lists with delivery integration in 2026 — MFP is moving downstream toward meal planning.
- **Strengths.** DB scale, barcode/voice/photo logging, ecosystem integrations.
- **Gaps vs Cookya.** No pantry inventory, no expiry, no cook-decrement, recipes are user-saved only; planning is templated, not pantry-anchored.

#### Cronometer
- **Platforms + pricing.** iOS, Android, web. Free is generous; Gold $4.99/mo annual or $10.99/mo; Pro $39.99/mo for individuals (coach-tier).
- **Core value prop.** Most accurate nutrition tracking; 84 nutrients, USDA-vetted DB, no user-submitted entries polluting it.
- **Relevant to Cookya.** Gold's "Oracle Nutrient Search" — given a deficit (e.g., low magnesium today), suggest foods that close the gap. This is _exactly_ the same pattern as Cookya's "protein gap > 20g → prioritize protein" recommendation, just at the food/ingredient level rather than recipe level. 2026 added beta AI Photo Logging.
- **Strengths.** Database integrity, micronutrient depth, accurate biometric handling.
- **Gaps vs Cookya.** Not a recipe app, not a pantry app, no meal-planning-from-inventory.

---

## 3. Where Cookya stands

### Closest competitive overlap
1. **Samsung Food** — feature-broadest. Has recipe + plan + pantry + nutrition + household + AI. But pantry isn't the _organizing primitive_ — it's a side feature, expiry support is reportedly fragile, and household is locked to Samsung accounts.
2. **Paprika** — closest match on pantry depth (quantities + expiry + grocery exclusion) and just doubled down on pantry in a Jan 2026 update. No AI generation; nutrition is BYO.
3. **DishGen / ChefGPT** — closest match on AI recipe generation as the primary loop and (for ChefGPT/MacrosChef) on macro-constrained generation. Lacks any persistent state.

### Combinations unique to Cookya
- **Expiry-bucket pantry (Use Soon / Available / Expired) as the recommendation primitive**, not just metadata. Nobody else surfaces "what's about to die" as the top-of-screen organizing UX.
- **Cooked-this flow that decrements pantry with safe-quantity validation.** Samsung Food has manual "remove what you used"; Paprika has expiry; nobody combines automatic decrement with quantity-safety guards.
- **Near-miss grocery suggestions tied to recipes** ("you're 1 ingredient away from this"). Implicit in some pantry-first apps but not surfaced as a flow.
- **Purchase → pantry confirmation loop** — the round-trip from grocery list back into inventory is a notable gap across the category.
- **Protein-gap-driven "Tonight's pick"** — Cronometer's Oracle does this for foods, ChefGPT's MacrosChef for one-shot generation, Eat This Much at plan-creation time. **No one does it as a recipe-recommendation reranker against a live pantry.** This is the single most defensible differentiator.

### Table-stakes gaps Cookya doesn't yet meet
- URL recipe import (Paprika, Samsung Food, AnyList).
- Real-time household sharing (AnyList specialty; Samsung Food has it).
- Grocery delivery integrations (Mealime, Eat This Much, Samsung Food, MFP+).
- Photo-based ingredient capture / fridge-snap (SuperCook, Plant Jammer, Samsung Food, Cronometer beta).
- Voice add to pantry (SuperCook).
- Smart appliance integration (Samsung Food only — but a moat for them, not a near-term need for Cookya).

---

## 4. UI/UX reference — patterns and anti-patterns

A visual and interaction reference for the closest competitors. Each entry links to the official store listing (where the screenshot carousel can be scrolled directly), names 2–4 specific patterns worth studying, and flags one or two anti-patterns to avoid. App Store / Play Store CDNs use rotating signed URLs that 403 outside the listing page, so most images are linked to their host page rather than embedded.

### SuperCook — pantry-first recipe finder

**Stores**
- iOS (2025 rebuild): [SuperCook - AI Meals & Scanner](https://apps.apple.com/us/app/supercook-ai-meals-scanner/id6743327665)
- iOS legacy: [SuperCook Recipe By Ingredient](https://apps.apple.com/us/app/supercook-recipe-by-ingredient/id1477747816)
- Android: [SuperCook on Google Play](https://play.google.com/store/apps/details?id=com.supercook.app&hl=en_US)

**Screenshots to study** (open the App Store listing above):
- Slide 1–2: pantry "ingredient cloud" — every ingredient is a tappable chip in a category-grouped grid
- Slide 3: camera scanner overlay — bounding boxes on detected items
- Slide 4–5: recipe results — recipes ranked by "missing ingredients: 0" first

**Patterns worth studying**
- **Tag-grid pantry, not a list.** Ingredients render as rounded chips grouped under collapsible category headers (Produce, Dairy, Meat). Tapping a chip toggles the green "in pantry" state instantly with no modal. Makes a 50-item pantry browsable in two screens of scroll, vs Paprika's row-per-item list which forces 8–10 screens.
- **Recipe rank with explicit "missing X ingredients" badge.** Each recipe card shows a count like "0 missing" or "missing: olive oil, paprika" right under the title, so the user understands why a recipe ranked where it did.
- **Voice-add mode.** A persistent mic button in the pantry tab opens a continuous-dictation overlay — say "tomatoes, onions, garlic" and chips light up in real time. No tap-to-confirm per item, just an "X" to remove a misheard one.
- **Camera scanner as a separate tab, not buried.** Fridge-snap is one of four primary tabs — CV ingestion is a first-class input alongside manual.

**Don't copy**
- The 2,000-ingredient catalog is wide but flat — sub-categories aren't searchable hierarchically, so finding "ghee" (under Dairy → Fats) requires scrolling. Cookya's autocomplete-first input is already better here.

### Samsung Food (formerly Whisk) — broadest feature surface

**Stores**
- iOS: [Samsung Food (App Store)](https://apps.apple.com/us/app/samsung-food/id1041437926) — Whisk listing rebranded in place
- Android: [Samsung Food on Play Store](https://play.google.com/store/apps/details?id=com.foodient.whisk)
- Marketing: [samsung.com/us/home-appliances/samsung-food/](https://www.samsung.com/us/home-appliances/samsung-food/)
- Press image of fridge-cam UI: [Samsung Newsroom — Food AI looks inside your fridge](https://news.samsung.com/us/new-food-ai-looks-inside-fridge-help-find-perfect-things-cook-already/)

**Screenshots to study**
- Marketing site hero carousel: meal plan calendar, fridge-cam recipe suggestions, recipe personalization toggle
- Newsroom article: ViewInside fridge camera output overlaid with detected items and recipe suggestions

**Patterns worth studying**
- **Recipe personalization toggle as a row of pills inside the recipe view.** Above the ingredient list sit chips like "Vegetarian", "Use what's in my fridge", "Cut servings to 2", "Lower carb". Tapping a chip rewrites the ingredient list in place with a brief shimmer. The strongest UX argument for putting LLM rewriting inside the recipe view rather than gating it behind a separate "modify" screen.
- **Recipe save via browser extension and share-sheet, with universal parser.** Long-press a link in any iOS app → share to Samsung Food → recipe lands with photo, ingredients (parsed into rows), steps, and source URL. The parsed-ingredient confirmation screen is editable before save.
- **Meal plan as a vertical week calendar with drag-to-reorder.** Each day is a card stack; drag a recipe from one day to another and the grocery list recalculates. Visible state, no hidden recompute.
- **Household sharing as a "Crew".** Plans, lists, and saved recipes belong to a Crew — joined via QR code on the inviter's phone.

**Reviews**
- [Samsung Food App Review UK (2026)](https://home-cooks.co.uk/pages/review-whisk)
- [Samsung Food Review: Pros and Cons — Plan to Eat (Jan 2026)](https://www.plantoeat.com/blog/2026/01/samsung-food-review-pros-and-cons/)

**Don't copy**
- Edits to a recipe (instructions, serving size) don't always propagate to the shopping list — a year-old user complaint. In Cookya, ingredient quantity changes must always cascade to the active grocery list in the same write.
- Fridge-cam is gated to Samsung hardware (Bespoke + Galaxy phones for Vision AI). Don't tie a core Cookya feature to hardware lock-in.

### Paprika Recipe Manager 3 — best non-AI pantry depth

**Stores**
- iOS: [Paprika Recipe Manager 3](https://apps.apple.com/us/app/paprika-recipe-manager-3/id1303222868)
- Android: [Paprika 3 on Google Play](https://play.google.com/store/apps/details?id=com.hindsightlabs.paprika.android.v3&hl=en_US)
- Help docs with annotated screenshots: [Paprika User Guide for Android](https://www.paprikaapp.com/help/android/)

**Screenshots to study**
- App Store slides 3–4: grocery list grouped by aisle with check-off targets
- Slides 5–6: recipe view with side-by-side ingredients/directions on iPad
- Help docs: pantry sort-by control with "Aisle / Date Added / Expiration Date / In Stock"

**Patterns worth studying**
- **Pantry sort-by selector with four orthogonal modes.** A single dropdown re-orders the entire pantry by aisle, date added, expiration, or in-stock. The right answer to "expiring soon" vs "what aisle do I need to restock" — both are valid views of the same data, no separate screens.
- **Quantity merging in the grocery list.** "1 egg" + "2 eggs" → "3 eggs" automatically, with source recipes listed under a disclosure toggle. The ingredient-name normalizer is the load-bearing piece.
- **Bidirectional pantry ↔ grocery.** Swipe pantry → grocery (when out); swipe grocery → pantry (when bought). One gesture, no menu.
- **Persistent "add item" input pinned to the toolbar.** No "+" → modal → keyboard-delay; the input is always visible. ~1.5 seconds saved per item on bulk entry.

**Reviews**
- [Paprika Recipe Manager 3 Review (2026) — Flavor365](https://flavor365.com/paprika-3-recipe-manager-our-honest-2026-review/)
- [Paprika App Review — Plan to Eat](https://www.plantoeat.com/blog/2023/07/paprika-app-review-pros-and-cons/)

**Don't copy**
- Adding a recipe to the meal plan does NOT auto-push its ingredients to the grocery list — invoke "Add to Groceries" per recipe. A frequently cited frustration. Cookya's plan → list flow should be one-write.
- Recipe view shows ingredients and directions as separate scrolling regions, forcing back-and-forth flipping. Inline ingredient references in step text (Mealime does this well) are better.
- Per-platform paid licenses (iOS, Mac, Win, Android sold separately) — modern users expect one subscription across devices.

### Mealime — meal planning + grocery lists

**Stores**
- iOS: [Mealime Meal Plans & Recipes](https://apps.apple.com/us/app/mealime-meal-plans-recipes/id1079999103)
- Android: [Mealime on Google Play](https://play.google.com/store/apps/details?id=com.mealime&hl=en_US)
- Marketing: [mealime.com](https://www.mealime.com/)

**Screenshots to study**
- Slides 1–3: diet/allergy onboarding (chips + toggles)
- Slide 4: recipe browser with "Add to Plan" plus button on each card
- Slide 5: aisle-grouped grocery list with checkboxes and strike-through animation
- Slide 6: in-recipe step-by-step cook view with inline ingredient pills

**Patterns worth studying**
- **Onboarding as a guided diet/allergen chip selector, not a long form.** Three screens: diet, allergens, dislikes. Total time-to-first-meal-plan: under 90 seconds.
- **Plus-icon-on-card recipe selection.** Browse the recipe grid, tap "+" on each one, then tap "Checkout" to confirm the plan. Mirrors e-commerce cart UX — already in users' muscle memory.
- **Aisle-grouped grocery list with sticky section headers + strike-through-not-delete on tap.** Tapping an item strikes it through and pushes it to a "got it" zone at the bottom of its aisle. Items don't disappear; undo is one tap.
- **Step-by-step cook mode with inline ingredient pills.** Step text shows ingredient names as pills ("dice the **2 cloves garlic**"); tapping a pill expands a tooltip showing the original quantity. The cook never has to scroll back.

**Don't copy**
- Recipe-swap suggestions on rejection cycle through the same 3–4 alternatives, with no way to browse the eligible set. Users feel boxed in. Cookya should always offer "browse all" alongside "next suggestion."

### AnyList — household-shared grocery

**Stores**
- iOS: [AnyList: Grocery Shopping List](https://apps.apple.com/us/app/anylist-grocery-shopping-list/id522167641)
- Android: [AnyList on Google Play](https://play.google.com/store/apps/details?id=com.purplecover.anylist&hl=en_US)
- Marketing: [anylist.com](https://www.anylist.com/)
- Help docs (lots of inline screenshots): [help.anylist.com — Getting Started](https://help.anylist.com/articles/getting-started/)

**Screenshots to study**
- Slides 1–2: shared grocery list with multiple users' avatars on items they added
- Slides 3–4: recipe import via Safari share sheet
- Slide 5: multi-list view (Costco, weekly groceries, Target)

**Patterns worth studying**
- **Per-item attribution avatars.** Items added by other household members show a small avatar — at the store you know who added an item (and who to text with questions). Light-touch, no chat overhead.
- **Multiple named lists, not one mega-list.** Each store / occasion is its own list. Sidebar swipe to switch. Avoids the "I only need 4 things from Costco but my list has 40" problem.
- **Recipe import via iOS share-sheet with parsed-ingredient confirmation.** Share → AnyList → confirmation screen with parsed name, photo, ingredient rows (each editable), steps. The confirm-before-save step is the trust-builder.
- **Photo-attached items.** Long-press → "Add Photo." Stays on the item in the shared list — the spouse buying the unfamiliar brand sees a picture instead of guessing.
- **Real-time sync with optimistic local updates.** Adding an item shows it instantly; sync resolves silently. No spinner.

**Reviews**
- [AnyList App Review — The Kitchn](https://www.thekitchn.com/anylist-app-review-23004503)
- [AnyList is the BEST app for keeping your household organized — Medium](https://missamandamae.medium.com/anylist-is-the-best-app-for-keeping-your-household-organized-c05cb6bb7e2b)

**Don't copy**
- Recipe organization beyond a flat list is weak — no smart collections, no auto-tagging by cuisine. Cookya can do better with LLM-generated tags.

### Eat This Much — macro-target plan generation

**Stores**
- iOS: [Eat This Much - Meal Planner](https://apps.apple.com/us/app/eat-this-much-meal-planner/id981637806)
- Android: [Eat This Much on Google Play](https://play.google.com/store/apps/details?id=com.eatthismuch&hl=en_US)
- Marketing: [eatthismuch.com](https://www.eatthismuch.com/)

**Screenshots to study**
- Slides 1–2: calorie/macro target setup with sliders
- Slides 3–4: day view with each meal's macro contribution stacked into a daily-total bar
- Slide 5: "swap meal" flow — tap a meal → 3–4 macro-equivalent alternatives

**Patterns worth studying**
- **Macro-bar as a persistent header on every day view.** Horizontal stacked bar at top showing protein/carbs/fat contributions per meal, plus a target line. Add or swap a meal and the bar recomputes live. The cleanest "did I hit my target?" surface in any meal-planning app.
- **Shuffle-meal control with macro-equivalence constraint.** Tap → "alternatives" sheet → 3–4 swaps that hit similar macros (so the day total doesn't drift). The constraint is shown explicitly: "within 50 cal / 5g protein."
- **Workout-day vs rest-day calorie split per weekday.** Toggle at plan setup defines different targets per day-of-week, planner respects it.
- **Onboarding tour overlaid as coachmark callouts on the actual UI.** No separate carousel; first launch shows arrows pointing at the real "Generate Plan" / "Grocery" / "Macros" buttons. Users land oriented to the actual UI, not a slide deck.

**Don't copy**
- Recipe browser feels database-flat — many similar entries, weak photo quality, hard to skim. If Cookya leans on LLM generation, photo quality and visual variety matter more.

### DishGen — AI recipe generation

(Picked over ChefGPT: stronger 2026 native iOS app, more visually distinctive chat-refinement UI; ChefGPT is mostly a webapp wrapper.)

**Stores**
- iOS: [DishGen: AI Recipes](https://apps.apple.com/us/app/dishgen-ai-recipes/id6473455744)
- Web: [dishgen.com](https://www.dishgen.com/) — see "How It Works" thumbnails on the landing page
- Generator UI: [dishgen.com/create](https://www.dishgen.com/create)
- Chat UI: [dishgen.com/chat](https://www.dishgen.com/chat)

**Screenshots to study**
- Landing page "How It Works" thumbnails
- Chat page: ChatGPT-style threaded refinement view with the live-updating recipe pinned on the right (web) / above the input (mobile)

**Patterns worth studying**
- **Single text prompt as the front door.** "help me create a healthy recipe for…" — one input, no required-field gauntlet. Model fills defaults; user refines via chat.
- **Live-updating recipe pinned to the chat.** As the user iterates ("make it vegan, halve the salt"), the recipe view rewrites in place rather than spawning a new card per turn. One canonical recipe.
- **Tool selector before submit (Recipe vs Meal Plan).** Two pills above the prompt switch the model's output schema. Cookya already has this conceptually — DishGen's version is the cleanest UI for it.
- **Save-to-collection from inside the chat.** Persistent "Save" on the active recipe card commits the latest iteration without leaving the chat.

**Reviews**
- [DishGen Review — Macaron](https://macaron.im/blog/dishgen-review)
- [Introducing DishGen — One Ingredient Chef](https://oneingredientchef.com/introducing-dishgen/)

**Don't copy**
- No real pantry concept — generation is open-prompt, "use what I have" is manual. Cookya's pantry → constraints → generation pipeline is a real moat over DishGen.
- Premium/Pro tiers ($7.99 / $15.99) are above the consumer comfort band for a single-purpose tool. Bundled value (pantry + plan + nutrition + generation) justifies a similar price.

---

## 5. Patterns Cookya should study for the Android rewrite

Synthesized from the references above. Each pattern names the competitor it's drawn from and the value it brings to Cookya's household-cooking-OS positioning.

1. **Tag-grid pantry with category collapse** _(SuperCook + Paprika sort-by)_. Replace any list-row pantry view with a chip grid grouped by category, plus a single sort-by control offering Aisle / Expiry / In-Stock / Recently Added. SuperCook's tap-to-toggle chips combined with Paprika's orthogonal sort modes.

2. **Voice-add to pantry as a persistent mic button** _(SuperCook)_. Continuous dictation that adds chips in real time. Critical for the "just unloaded groceries" moment when typing one-by-one is friction. Especially valuable for Indian-cuisine users adding 10+ spices in one sitting.

3. **Fridge-snap onboarding** _(Samsung Food + SuperCook)_. Camera input → CV detects items → user confirms list (edit chip names, remove false positives) before items commit to the pantry. The confirm-before-commit step is what AnyList does for recipe imports and what Samsung's fridge AI omits, to its detriment.

4. **In-recipe "personalization chips" that rewrite ingredients in place** _(Samsung Food)_. Above the ingredient list, show pills like "Use what's in my pantry", "Halve servings", "Make vegetarian", "Indian style". Tapping one triggers an LLM rewrite in place, with a shimmer transition and an Undo affordance. The killer pattern for an LLM-powered cooking app.

5. **Aisle-grouped grocery list with sticky headers, per-item avatars, and strike-through-not-delete** _(AnyList + Mealime)_. Multi-user attribution from AnyList plus Mealime's "got it" lower zone. Items don't disappear on tap — they strike through and float to the bottom of their aisle, undo is one tap, section header stays sticky during long aisle scrolls.

6. **Plan-to-list one-write flow** _(inverse of Paprika's biggest complaint)_. Adding a recipe to the meal plan must atomically push its ingredients to the active grocery list, with quantity-merging across recipes ("3 eggs from omelet + 2 eggs from cake = 5 eggs"). Editing a recipe's serving size must propagate. Correctness pattern, not just an interaction pattern.

7. **Macro-bar header on every plan day** _(Eat This Much)_. A persistent horizontal stacked bar showing protein/carbs/fat contribution per meal against a target line. Cookya's nutrition gap layer needs this surface — it's the only way the user feels the gap they're closing.

8. **Live-updating recipe pinned to the LLM chat** _(DishGen)_. When the user is in "modify recipe" or "generate" chat, the recipe view rewrites in place rather than spawning a new card per turn. One canonical recipe, threaded refinement underneath. Save commits the current state.

9. **(Stretch) Coachmark-on-real-UI onboarding** _(Eat This Much)_. First launch shows arrows pointing at the actual primary buttons in the actual app shell. Cuts time-to-first-action; avoids the "now where was that thing from the tutorial?" moment.

---

## 6. Strategic moves

Recommendations that follow from the analysis. These are not commitments — they're inputs to the next planning round. When one is decided, capture the rationale in `DECISIONS.md` and the scope/timing in `PLANNING.md`.

1. **Lead with the unique triad as the marketing story.** "Knows what's expiring, knows what you're short on (protein), updates itself when you cook." Don't position as another AI-recipe app — DishGen/ChefGPT win that race on speed alone. The triad is the moat; AI generation is the engine, not the pitch.

2. **Cheap credibility unlocks for the Android launch:** URL recipe import + photo-based pantry add. Both are 2026 baseline expectations and close the most visible gap against Samsung Food and Paprika. Recipe import in particular cures the cold-start friction that hurt Paprika historically.

3. **Commit to household sharing as a paid anchor.** Supabase makes shared pantry/list realistic. AnyList already proves household is a $14.99/yr WTP anchor. This is also where Cookya can outflank Samsung Food, whose household story is locked to the Samsung account ecosystem.

4. **(Optional, later) Fill the PlateJoy vacancy.** PlateJoy shut down in 2025 — "personalized meal plan that respects your real pantry and macro goals" is now an open positioning. Cookya already has the primitives (NutritionGoals from biometrics, weekly plan, pantry-aware recipes) that PlateJoy never tied together.

---

## 7. Sources

### Competitor profiles
- [SuperCook on the App Store](https://apps.apple.com/us/app/supercook-recipe-by-ingredient/id1477747816)
- [SuperCook official site](https://www.supercook.com/)
- [SuperCook review (mindwobble)](https://mindwobble.com/software/supercook/)
- [Plant Jammer (listmyai)](https://listmyai.net/tool/plant-jammer)
- [Plant Jammer funding coverage](https://www.theplantbasemag.com/news/plant-jammer-secures-4m-euros-in-funding-for-its-ai-recipe-technology-1)
- [Samsung Food official](https://samsungfood.com/)
- [Samsung Food review (Plan to Eat, Jan 2026)](https://www.plantoeat.com/blog/2026/01/samsung-food-review-pros-and-cons/)
- [Samsung Food 2026 alternatives + Vision AI](https://mealthinker.com/blog/samsung-food-alternative)
- [Samsung Food Food List help](https://support.samsungfood.com/hc/en-us/articles/30025317487508-Getting-Started-with-Food-List)
- [DishGen review 2026 (Macaron)](https://macaron.im/blog/dishgen-review)
- [ChefGPT review 2026 (Nemovideo)](https://www.nemovideo.com/alternative/chefgpt)
- [Best AI recipe generators 2026 (FoodsGPT)](https://foodsgpt.com/blog/best-ai-recipe-generators-2026)
- [Mealime official](https://www.mealime.com/)
- [Mealime free-tier 2026 changes](https://mealthinker.com/blog/mealime-alternative)
- [Paprika official](https://www.paprikaapp.com/)
- [Paprika 2026 review (Flavor365)](https://flavor365.com/paprika-3-recipe-manager-our-honest-2026-review/)
- [Paprika 2026 sentiment (Marlvel)](https://marlvel.ai/intel-report/lifestyle/paprika-recipe-manager-3-1)
- [AnyList official](https://www.anylist.com/)
- [AnyList Complete features](https://www.anylist.com/complete)
- [Eat This Much pricing](https://www.eatthismuch.com/pricing)
- [Eat This Much 2026 review](https://www.promealplan.com/en/blog/eat-this-much-review-2026)
- [PlateJoy shutdown notice](https://mealthinker.com/blog/platejoy-alternative)
- [MyFitnessPal pricing 2026](https://nutriscan.app/blog/posts/myfitnesspal-pricing-2026-guide-2ff09c399a)
- [MyFitnessPal Premium vs Premium+ 2026](https://nutriscan.app/blog/posts/myfitnesspal-premium-vs-premium-plus-features-62075fe756)
- [Cronometer pricing 2026](https://nutriscan.app/blog/posts/cronometer-pricing-2026-basic-vs-gold-vs-pro-b28e621201)
- [Cronometer Gold features 2026](https://nutriscan.app/blog/posts/cronometer-gold-cost-2026-features-unlock-ff7295a14c)
- [Cronometer 2026 review (calorie-trackers)](https://calorie-trackers.com/reviews/cronometer/)
- [Best meal-planning apps with pantry tracking 2026](https://mealthinker.com/blog/meal-planning-app-pantry-tracking)

### UI/UX references
- [SuperCook - AI Meals & Scanner (App Store)](https://apps.apple.com/us/app/supercook-ai-meals-scanner/id6743327665)
- [SuperCook (Google Play)](https://play.google.com/store/apps/details?id=com.supercook.app&hl=en_US)
- [Top 12 Best Cooking Apps for Android 2026](https://www.recipeone.app/blog/best-cooking-apps-for-android)
- [Samsung Food App Review UK 2026](https://home-cooks.co.uk/pages/review-whisk)
- [Samsung Newsroom — Food AI Looks Inside Your Fridge](https://news.samsung.com/us/new-food-ai-looks-inside-fridge-help-find-perfect-things-cook-already/)
- [Samsung Food product page](https://www.samsung.com/us/home-appliances/samsung-food/)
- [Paprika Recipe Manager 3 (App Store)](https://apps.apple.com/us/app/paprika-recipe-manager-3/id1303222868)
- [Paprika 3 (Google Play)](https://play.google.com/store/apps/details?id=com.hindsightlabs.paprika.android.v3&hl=en_US)
- [Paprika App Review — Plan to Eat](https://www.plantoeat.com/blog/2023/07/paprika-app-review-pros-and-cons/)
- [Paprika Android user guide](https://www.paprikaapp.com/help/android/)
- [Mealime (App Store)](https://apps.apple.com/us/app/mealime-meal-plans-recipes/id1079999103)
- [Mealime (Google Play)](https://play.google.com/store/apps/details?id=com.mealime&hl=en_US)
- [Mealime Getting Started Guide](https://support.mealime.com/article/151-getting-started-guide)
- [AnyList (App Store)](https://apps.apple.com/us/app/anylist-grocery-shopping-list/id522167641)
- [AnyList (Google Play)](https://play.google.com/store/apps/details?id=com.purplecover.anylist&hl=en_US)
- [AnyList App Review — The Kitchn](https://www.thekitchn.com/anylist-app-review-23004503)
- [AnyList recipe import help](https://help.anylist.com/articles/feature-overview-recipe-import/)
- [Eat This Much (App Store)](https://apps.apple.com/us/app/eat-this-much-meal-planner/id981637806)
- [Eat This Much (Google Play)](https://play.google.com/store/apps/details?id=com.eatthismuch&hl=en_US)
- [DishGen: AI Recipes (App Store)](https://apps.apple.com/us/app/dishgen-ai-recipes/id6473455744)
- [DishGen site](https://www.dishgen.com/)
- [DishGen Review — Macaron](https://macaron.im/blog/dishgen-review)
- [Introducing DishGen — One Ingredient Chef](https://oneingredientchef.com/introducing-dishgen/)
