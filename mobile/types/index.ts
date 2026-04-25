export interface PantryItem {
  id: string
  user_id: string
  name: string
  quantity_text: string
  category: string
  expiry_date: string | null
  updated_at: string
}

export interface GroceryItem {
  id: string
  user_id: string
  name: string
  quantity_text: string
  category: string
  note: string | null
  source: string
  reason_recipes: string[]
  created_at: string
}

export interface Ingredient {
  name: string
  quantity: string
}

export interface Recipe {
  id: string
  title: string
  ingredients: Ingredient[]
  instructions: string[]
  calories: number
  protein: number
  carbs: number
  fat: number
  fiber: number
  difficulty: string
}

export interface SavedRecipe {
  id: string
  user_id: string
  recipe: Recipe
  profile_id: string
  profile_name_snapshot: string
  saved_at: string
  is_favorite: boolean
}

export interface CookedMealRecord {
  id: string
  user_id: string
  cooked_at: string
  profile_id: string
  profile_name_snapshot: string
  recipe_title: string
  recipe_ingredients: Ingredient[]
  calories: number
  protein_g: number
  carbs_g: number
  fat_g: number
  fiber_g: number
}

export interface NutritionGoals {
  daily_calories: number
  daily_protein_g: number
}

export interface UserProfile {
  id: string
  user_id: string
  name: string
  age: number | null
  weight_kg: number | null
  height_cm: number | null
  is_vegetarian: boolean
  avoid_food_items: string[]
  nutrition_goals: NutritionGoals | null
  created_at: string
  updated_at: string
}

export interface WeeklyPlanMeal {
  id: string
  user_id: string
  saved_recipe_id: string
  recipe_title: string
  added_at: string
}
