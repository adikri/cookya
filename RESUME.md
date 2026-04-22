## Interrupted: 2026-04-22

**Branch:** codex/nutrition-layer
**Last commit:** 2089c58 (Update PLANNING.md to nutrition-first roadmap)

**Was working on:**
Building the nutrition layer — Recipe macros, NutritionGoals in UserProfile, CookedMealRecord macro snapshot, OpenAI/Worker schema changes, goal-aware generation prompt.

**Done this session (not yet committed):**
- (in progress)

**Exact next step:**
1. Create `cookya/Models/NutritionGoals.swift` and add to project
2. Update `Recipe.swift` — add protein/carbs/fat/fiber
3. Update `CookedMealRecord.swift` — add macro snapshot fields
4. Update `UserProfile.swift` — add nutritionGoals field
5. Update `RecipeGenerationRequest.swift` — add nutritionGap
6. Update `CookedMealStore.swift` — macro snapshot + todayNutrition()
7. Update `OpenAIRecipeService.swift` — extend schema + prompt
8. Update `BackendRecipeService.swift` — pass nutritionGap
9. Update `worker/src/index.ts` — extend Recipe type + schema + prompt
10. Update `RecipeViewModel.swift` — accept nutritionGap param

**Open questions / blockers:**
None.
