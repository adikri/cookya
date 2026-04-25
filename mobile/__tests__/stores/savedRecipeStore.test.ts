import { useSavedRecipeStore } from '../../stores/savedRecipeStore'
import { Recipe, SavedRecipe } from '../../types'

jest.mock('../../services/supabase', () => ({
  supabase: { from: jest.fn(), auth: { getUser: jest.fn() } },
}))

import { supabase } from '../../services/supabase'
const mockFrom = supabase.from as jest.Mock

const initialState = { recipes: [], isLoading: false, error: null }

const mockRecipe = (): Recipe => ({
  id: crypto.randomUUID(),
  title: 'Dal Tadka', ingredients: [], instructions: [],
  calories: 400, protein: 18, carbs: 50, fat: 8, fiber: 6, difficulty: 'easy',
})

const mockSaved = (overrides?: Partial<SavedRecipe>): SavedRecipe => ({
  id: crypto.randomUUID(), user_id: 'u1', recipe: mockRecipe(),
  profile_id: 'p1', profile_name_snapshot: 'Adi',
  saved_at: '2026-01-01T00:00:00Z', is_favorite: false,
  ...overrides,
})

beforeEach(() => {
  useSavedRecipeStore.setState(initialState)
  jest.clearAllMocks()
})

describe('fetchRecipes', () => {
  it('sets recipes on success', async () => {
    const items = [mockSaved(), mockSaved()]
    mockFrom.mockReturnValue({ select: () => ({ order: () => Promise.resolve({ data: items, error: null }) }) })
    await useSavedRecipeStore.getState().fetchRecipes()
    expect(useSavedRecipeStore.getState().recipes).toEqual(items)
  })
})

describe('saveRecipe', () => {
  it('prepends saved recipe on success', async () => {
    const recipe = mockRecipe()
    const saved = mockSaved({ recipe })
    mockFrom.mockReturnValue({ insert: () => ({ select: () => Promise.resolve({ data: [saved], error: null }) }) })
    await useSavedRecipeStore.getState().saveRecipe(recipe, 'u1', 'p1', 'Adi')
    expect(useSavedRecipeStore.getState().recipes[0]).toEqual(saved)
  })

  it('skips if recipe already saved', async () => {
    const recipe = mockRecipe()
    const existing = mockSaved({ recipe })
    useSavedRecipeStore.setState({ recipes: [existing], isLoading: false, error: null })
    await useSavedRecipeStore.getState().saveRecipe(recipe, 'u1', 'p1', 'Adi')
    expect(useSavedRecipeStore.getState().recipes).toHaveLength(1)
    expect(mockFrom).not.toHaveBeenCalled()
  })
})

describe('toggleFavorite', () => {
  it('optimistically toggles and persists', async () => {
    const item = mockSaved({ is_favorite: false })
    useSavedRecipeStore.setState({ recipes: [item], isLoading: false, error: null })
    mockFrom.mockReturnValue({ update: () => ({ eq: () => Promise.resolve({ error: null }) }) })
    await useSavedRecipeStore.getState().toggleFavorite(item.id, false)
    expect(useSavedRecipeStore.getState().recipes[0].is_favorite).toBe(true)
  })

  it('reverts on failure', async () => {
    const item = mockSaved({ is_favorite: false })
    useSavedRecipeStore.setState({ recipes: [item], isLoading: false, error: null })
    mockFrom.mockReturnValue({ update: () => ({ eq: () => Promise.resolve({ error: new Error('fail') }) }) })
    await useSavedRecipeStore.getState().toggleFavorite(item.id, false)
    expect(useSavedRecipeStore.getState().recipes[0].is_favorite).toBe(false)
  })
})

describe('deleteRecipe', () => {
  it('removes recipe optimistically', async () => {
    const items = [mockSaved(), mockSaved()]
    useSavedRecipeStore.setState({ recipes: items, isLoading: false, error: null })
    mockFrom.mockReturnValue({ delete: () => ({ eq: () => Promise.resolve({ error: null }) }) })
    await useSavedRecipeStore.getState().deleteRecipe(items[0].id)
    expect(useSavedRecipeStore.getState().recipes).toHaveLength(1)
    expect(useSavedRecipeStore.getState().recipes[0].id).toBe(items[1].id)
  })

  it('reverts on failure', async () => {
    const items = [mockSaved(), mockSaved()]
    useSavedRecipeStore.setState({ recipes: items, isLoading: false, error: null })
    mockFrom.mockReturnValue({ delete: () => ({ eq: () => Promise.resolve({ error: new Error('fail') }) }) })
    await useSavedRecipeStore.getState().deleteRecipe(items[0].id)
    expect(useSavedRecipeStore.getState().recipes).toHaveLength(2)
  })
})
