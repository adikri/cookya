import { getHomeRecommendation, RecommendationInput } from '../../services/homeRecommendationEngine'
import { PantryItem, SavedRecipe } from '../../types'

function makePantryItem(name: string): PantryItem {
  return { id: name, user_id: 'u1', name, quantity_text: '1', category: 'Other', expiry_date: null, updated_at: '' }
}

function makeSavedRecipe(overrides: Partial<SavedRecipe['recipe']> & Pick<SavedRecipe['recipe'], 'protein'>, isFavorite = false): SavedRecipe {
  return {
    id: String(Math.random()),
    user_id: 'u1',
    profile_id: 'u1',
    profile_name_snapshot: 'Me',
    saved_at: '',
    is_favorite: isFavorite,
    recipe: {
      id: 'r1',
      title: 'Recipe',
      ingredients: [],
      instructions: [],
      calories: 400,
      protein: overrides.protein,
      carbs: 40,
      fat: 10,
      fiber: 5,
      difficulty: 'Easy',
    },
  }
}

function input(partial: Partial<RecommendationInput>): RecommendationInput {
  return {
    pantryItems: [],
    savedRecipes: [],
    todayProteinG: 0,
    dailyProteinGoal: 0,
    ...partial,
  }
}

const pantry = [makePantryItem('Rice'), makePantryItem('Dal')]

describe('getHomeRecommendation', () => {
  test('fill-pantry when pantry is empty', () => {
    const result = getHomeRecommendation(input({ pantryItems: [] }))
    expect(result).toEqual({ type: 'fill-pantry' })
  })

  test('null when pantry present, no goals, no saved recipes', () => {
    const result = getHomeRecommendation(input({ pantryItems: pantry }))
    expect(result).toBeNull()
  })

  test('null when protein gap <= 20g even with saved recipes', () => {
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [makeSavedRecipe({ protein: 30 })],
      dailyProteinGoal: 100,
      todayProteinG: 85,
    }))
    expect(result).toBeNull()
  })

  test('tonight-pick when protein gap > 20g and saved recipes exist', () => {
    const r1 = makeSavedRecipe({ protein: 30 })
    const r2 = makeSavedRecipe({ protein: 45 })
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [r1, r2],
      dailyProteinGoal: 120,
      todayProteinG: 50,
    }))
    expect(result).toMatchObject({ type: 'tonight-pick', recipe: r2, proteinGap: 70 })
  })

  test('tonight-pick selects highest-protein recipe', () => {
    const low = makeSavedRecipe({ protein: 20 })
    const high = makeSavedRecipe({ protein: 60 })
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [low, high],
      dailyProteinGoal: 150,
      todayProteinG: 0,
    }))
    expect(result).toMatchObject({ type: 'tonight-pick', recipe: high })
  })

  test('no tonight-pick when protein goal is 0', () => {
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [makeSavedRecipe({ protein: 50 })],
      dailyProteinGoal: 0,
      todayProteinG: 0,
    }))
    expect(result).toBeNull()
  })

  test('cook-favorite when no protein gap but has a favorite', () => {
    const fav = makeSavedRecipe({ protein: 30 }, true)
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [fav],
    }))
    expect(result).toMatchObject({ type: 'cook-favorite', recipe: fav })
  })

  test('tonight-pick takes priority over cook-favorite', () => {
    const fav = makeSavedRecipe({ protein: 20 }, true)
    const high = makeSavedRecipe({ protein: 55 })
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [high, fav],
      dailyProteinGoal: 120,
      todayProteinG: 0,
    }))
    expect(result?.type).toBe('tonight-pick')
  })

  test('null when saved recipes exist but none are favorites and no protein goal', () => {
    const result = getHomeRecommendation(input({
      pantryItems: pantry,
      savedRecipes: [makeSavedRecipe({ protein: 30 })],
    }))
    expect(result).toBeNull()
  })
})
