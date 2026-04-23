-- ============================================================
-- Cookya Schema v1 — applied 2026-04-23
-- ============================================================
--
-- Design notes:
-- - Every table has user_id UUID REFERENCES auth.users(id) as the RLS anchor
-- - Nested Swift structs (Recipe, Ingredient[], PantryConsumption[], NutritionGoals)
--   stored as JSONB — maps directly to existing Codable models, no join tables needed
-- - profiles.id = local iOS UserProfile.id (preserved to avoid model churn now)
--   profiles.user_id = auth.uid() — unique 1:1 constraint
--   Migration path when household accounts ship: make user_id the PK and
--   update saved_recipes/cooked_meal_records profile_id to reference auth.users(id)

-- ------------------------------------------------------------
-- pantry_items
-- ------------------------------------------------------------
CREATE TABLE pantry_items (
    id              UUID        PRIMARY KEY,
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name            TEXT        NOT NULL,
    quantity_text   TEXT        NOT NULL DEFAULT '',
    category        TEXT        NOT NULL DEFAULT 'pantry',
    expiry_date     TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ NOT NULL
);

CREATE INDEX pantry_items_user_id_idx ON pantry_items (user_id);

ALTER TABLE pantry_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own pantry items"
    ON pantry_items FOR ALL
    USING  (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------
-- grocery_items
-- ------------------------------------------------------------
CREATE TABLE grocery_items (
    id              UUID        PRIMARY KEY,
    user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name            TEXT        NOT NULL,
    quantity_text   TEXT        NOT NULL DEFAULT '',
    category        TEXT        NOT NULL DEFAULT 'pantry',
    note            TEXT,
    source          TEXT        NOT NULL DEFAULT 'manual',
    reason_recipes  TEXT[]      NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL
);

CREATE INDEX grocery_items_user_id_idx ON grocery_items (user_id);

ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own grocery items"
    ON grocery_items FOR ALL
    USING  (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------
-- saved_recipes
-- recipe column holds the full Recipe struct as JSONB
-- ------------------------------------------------------------
CREATE TABLE saved_recipes (
    id                    UUID        PRIMARY KEY,
    user_id               UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe                JSONB       NOT NULL,
    profile_id            UUID        NOT NULL,
    profile_name_snapshot TEXT        NOT NULL,
    saved_at              TIMESTAMPTZ NOT NULL,
    is_favorite           BOOLEAN     NOT NULL DEFAULT false
);

CREATE INDEX saved_recipes_user_id_idx ON saved_recipes (user_id);

ALTER TABLE saved_recipes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own saved recipes"
    ON saved_recipes FOR ALL
    USING  (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------
-- cooked_meal_records
-- recipe_ingredients and consumptions stored as JSONB arrays
-- ------------------------------------------------------------
CREATE TABLE cooked_meal_records (
    id                    UUID        PRIMARY KEY,
    user_id               UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    cooked_at             TIMESTAMPTZ NOT NULL,
    profile_id            UUID        NOT NULL,
    profile_name_snapshot TEXT        NOT NULL,
    recipe_title          TEXT        NOT NULL,
    recipe_ingredients    JSONB       NOT NULL DEFAULT '[]',
    consumptions          JSONB       NOT NULL DEFAULT '[]',
    warnings              TEXT[]      NOT NULL DEFAULT '{}',
    calories              INT         NOT NULL DEFAULT 0,
    protein_g             INT         NOT NULL DEFAULT 0,
    carbs_g               INT         NOT NULL DEFAULT 0,
    fat_g                 INT         NOT NULL DEFAULT 0,
    fiber_g               INT         NOT NULL DEFAULT 0
);

CREATE INDEX cooked_meal_records_user_id_idx     ON cooked_meal_records (user_id);
CREATE INDEX cooked_meal_records_cooked_at_idx   ON cooked_meal_records (user_id, cooked_at DESC);

ALTER TABLE cooked_meal_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own cooked meal records"
    ON cooked_meal_records FOR ALL
    USING  (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------
-- weekly_plan_meals
-- ------------------------------------------------------------
CREATE TABLE weekly_plan_meals (
    id               UUID        PRIMARY KEY,
    user_id          UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    saved_recipe_id  UUID        NOT NULL,
    recipe_title     TEXT        NOT NULL,
    added_at         TIMESTAMPTZ NOT NULL
);

CREATE INDEX weekly_plan_meals_user_id_idx ON weekly_plan_meals (user_id);

ALTER TABLE weekly_plan_meals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own weekly plan"
    ON weekly_plan_meals FOR ALL
    USING  (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);


-- ------------------------------------------------------------
-- profiles
-- id     = local iOS UserProfile.id (preserved — see design notes above)
-- user_id = auth.uid() — unique 1:1 with auth user
-- nutrition_goals stored as JSONB {dailyCalories, dailyProteinG}
-- ------------------------------------------------------------
CREATE TABLE profiles (
    id                 UUID              PRIMARY KEY,
    user_id            UUID              NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name               TEXT              NOT NULL,
    type               TEXT              NOT NULL DEFAULT 'registered',
    age                INT,
    weight_kg          DOUBLE PRECISION,
    height_cm          DOUBLE PRECISION,
    location           TEXT,
    is_vegetarian      BOOLEAN           NOT NULL DEFAULT false,
    avoid_food_items   TEXT[]            NOT NULL DEFAULT '{}',
    nutrition_goals    JSONB,
    created_at         TIMESTAMPTZ       NOT NULL,
    updated_at         TIMESTAMPTZ       NOT NULL
);

CREATE INDEX profiles_user_id_idx ON profiles (user_id);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own profile"
    ON profiles FOR ALL
    USING  (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
