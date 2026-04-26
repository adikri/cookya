import { PantryItem, SavedRecipe } from '../types'

export type HomeRecommendation =
  | { type: 'fill-pantry' }
  | { type: 'tonight-pick'; recipe: SavedRecipe; proteinGap: number }
  | { type: 'cook-favorite'; recipe: SavedRecipe }

export interface RecommendationInput {
  pantryItems: PantryItem[]
  savedRecipes: SavedRecipe[]
  todayProteinG: number
  dailyProteinGoal: number
}

export function getHomeRecommendation(input: RecommendationInput): HomeRecommendation | null {
  const { pantryItems, savedRecipes, todayProteinG, dailyProteinGoal } = input

  if (pantryItems.length === 0) {
    return { type: 'fill-pantry' }
  }

  const proteinGap = dailyProteinGoal - todayProteinG
  if (dailyProteinGoal > 0 && proteinGap > 20 && savedRecipes.length > 0) {
    const best = savedRecipes.reduce<SavedRecipe | null>((b, r) =>
      !b || r.recipe.protein > b.recipe.protein ? r : b, null)!
    return { type: 'tonight-pick', recipe: best, proteinGap: Math.round(proteinGap) }
  }

  const favorite = savedRecipes.find(r => r.is_favorite)
  if (favorite) {
    return { type: 'cook-favorite', recipe: favorite }
  }

  return null
}
