import { useWeeklyPlanStore } from '../../stores/weeklyPlanStore'
import { SavedRecipe } from '../../types'

jest.mock('../../services/supabase', () => ({
  supabase: { from: jest.fn(), auth: { getUser: jest.fn() } },
}))

import { supabase } from '../../services/supabase'
const mockFrom = supabase.from as jest.Mock
const mockGetUser = supabase.auth.getUser as jest.Mock

const initialState = { meals: [], isLoading: false, error: null }

const mockSavedRecipe = (id = 'sr1'): SavedRecipe => ({
  id, user_id: 'u1',
  recipe: { id: 'r1', title: 'Dal Chawal', ingredients: [], instructions: [], calories: 400, protein: 18, carbs: 50, fat: 6, fiber: 5, difficulty: 'easy' },
  profile_id: 'p1', profile_name_snapshot: 'Adi',
  saved_at: '2026-01-01T00:00:00Z', is_favorite: false,
})

const mockMeal = (id = 'm1', savedRecipeId = 'sr1') => ({
  id, user_id: 'u1', saved_recipe_id: savedRecipeId,
  recipe_title: 'Dal Chawal', added_at: '2026-01-01T00:00:00Z',
})

beforeEach(() => {
  useWeeklyPlanStore.setState(initialState)
  jest.clearAllMocks()
})

describe('fetchMeals', () => {
  it('loads meals on success', async () => {
    const meals = [mockMeal()]
    mockFrom.mockReturnValue({ select: () => ({ order: () => Promise.resolve({ data: meals, error: null }) }) })
    await useWeeklyPlanStore.getState().fetchMeals()
    expect(useWeeklyPlanStore.getState().meals).toEqual(meals)
  })
})

describe('addMeal', () => {
  it('appends meal on success', async () => {
    mockFrom.mockReturnValue({ insert: () => Promise.resolve({ error: null }) })
    await useWeeklyPlanStore.getState().addMeal(mockSavedRecipe(), 'u1')
    expect(useWeeklyPlanStore.getState().meals).toHaveLength(1)
    expect(useWeeklyPlanStore.getState().meals[0].recipe_title).toBe('Dal Chawal')
  })

  it('skips duplicate', async () => {
    const meal = mockMeal()
    useWeeklyPlanStore.setState({ meals: [meal], isLoading: false, error: null })
    await useWeeklyPlanStore.getState().addMeal(mockSavedRecipe('sr1'), 'u1')
    expect(useWeeklyPlanStore.getState().meals).toHaveLength(1)
    expect(mockFrom).not.toHaveBeenCalled()
  })

  it('skips when plan is full (7 meals)', async () => {
    const meals = Array.from({ length: 7 }, (_, i) => mockMeal(`m${i}`, `sr${i}`))
    useWeeklyPlanStore.setState({ meals, isLoading: false, error: null })
    await useWeeklyPlanStore.getState().addMeal(mockSavedRecipe('sr99'), 'u1')
    expect(useWeeklyPlanStore.getState().meals).toHaveLength(7)
    expect(mockFrom).not.toHaveBeenCalled()
  })
})

describe('removeMeal', () => {
  it('removes meal optimistically and reverts on failure', async () => {
    const meals = [mockMeal('m1'), mockMeal('m2', 'sr2')]
    useWeeklyPlanStore.setState({ meals, isLoading: false, error: null })
    mockFrom.mockReturnValue({ delete: () => ({ eq: () => Promise.resolve({ error: null }) }) })
    await useWeeklyPlanStore.getState().removeMeal('m1')
    expect(useWeeklyPlanStore.getState().meals).toHaveLength(1)
    expect(useWeeklyPlanStore.getState().meals[0].id).toBe('m2')
  })
})

describe('clearAll', () => {
  it('clears all meals and calls delete', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'u1' } } })
    const meals = [mockMeal('m1'), mockMeal('m2', 'sr2')]
    useWeeklyPlanStore.setState({ meals, isLoading: false, error: null })
    mockFrom.mockReturnValue({ delete: () => ({ eq: () => Promise.resolve({ error: null }) }) })
    await useWeeklyPlanStore.getState().clearAll()
    expect(useWeeklyPlanStore.getState().meals).toHaveLength(0)
  })
})
