## Interrupted: 2026-04-22

**Branch:** codex/nutrition-layer
**Last commit:** 3ffcd6a (Add nutrition layer: macros, goals, goal-aware generation, and test infra fix)

**Was working on:**
Bug fix: worker purchase endpoint duplicate pantry item.

**Done this session (not yet committed):**
- Fixed `worker/src/index.ts`: `POST /v1/grocery/{id}/purchase` now uses `id: id` instead of `id: crypto.randomUUID()` so the returned pantry item's ID matches the local placeholder iOS already inserted. Prevents duplicate pantry entries on first purchase of an ingredient (and on fresh purchase when an expired item of the same name exists).
- Updated `PLANNING.md`: Phase A items 3 & 4 (recipe cache eviction, store hardening) marked Built; section 4 debt list trimmed to reflect current reality.

**Exact next step:**
1. Commit these changes (worker fix + PLANNING.md update)
2. Continue with Phase N nutrition-home: Today's nutrition progress card on HomeView + "Tonight's pick" recommendation
