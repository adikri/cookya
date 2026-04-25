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
