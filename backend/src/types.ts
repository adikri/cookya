export type InventoryCategory =
  | "produce"
  | "dairy"
  | "meat"
  | "seafood"
  | "pantry"
  | "bakery"
  | "frozen"
  | "snacks"
  | "beverages"
  | "condiments"
  | "spices"
  | "other";

export type Difficulty = "easy" | "medium" | "hard";

export interface BackendPantryItem {
  id: string; // UUID string
  name: string;
  availableQuantityText: string;
  selectedQuantityText: string;
  category: InventoryCategory;
  expiryDate: string | null; // ISO8601 or null
}

export interface Ingredient {
  name: string;
  quantity: string;
}

export interface UserProfile {
  isVegetarian?: boolean;
  avoidFoodItems?: string[];
  location?: string;
}

export interface BackendRecipeGenerateRequest {
  pantryItems: BackendPantryItem[];
  manualIngredients: Ingredient[];
  difficulty: Difficulty;
  servings: number;
  profile?: UserProfile | null;
  prioritizedIngredientNames: string[];
  locationContext?: string | null;
}

export interface Recipe {
  title: string;
  ingredients: Ingredient[];
  instructions: string[];
  calories: number;
  difficulty: Difficulty;
}

export interface ErrorResponse {
  error: {
    message: string;
  };
}

