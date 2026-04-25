import { useCookedMealStore } from '../../stores/cookedMealStore'
import { Recipe } from '../../types'

jest.mock('../../services/supabase', () => ({
  supabase: { from: jest.fn(), auth: { getUser: jest.fn() } },
}))

import { supabase } from '../../services/supabase'
const mockFrom = supabase.from as jest.Mock

const initialState = { records: [], todayCalories: 0, todayProteinG: 0, isLoading: false, error: null }

const mockRecipe = (): Recipe => ({
  id: 'r1', title: 'Dal Chawal', ingredients: [], instructions: [],
  calories: 450, protein: 18, carbs: 72, fat: 6, fiber: 8, difficulty: 'easy',
})

beforeEach(() => {
  useCookedMealStore.setState(initialState)
  jest.clearAllMocks()
})

describe('fetchToday', () => {
  it('aggregates today calories and protein', async () => {
    const records = [
      { id: '1', calories: 400, protein_g: 20 },
      { id: '2', calories: 300, protein_g: 15 },
    ]
    mockFrom.mockReturnValue({
      select: () => ({ gte: () => ({ order: () => Promise.resolve({ data: records, error: null }) }) }),
    })
    await useCookedMealStore.getState().fetchToday()
    expect(useCookedMealStore.getState().todayCalories).toBe(700)
    expect(useCookedMealStore.getState().todayProteinG).toBe(35)
  })
})

describe('logCooked', () => {
  it('increments today totals and prepends record', async () => {
    mockFrom.mockReturnValue({ insert: () => Promise.resolve({ error: null }) })
    const recipe = mockRecipe()
    await useCookedMealStore.getState().logCooked(recipe, 'u1', 'p1', 'Adi')
    const state = useCookedMealStore.getState()
    expect(state.todayCalories).toBe(450)
    expect(state.todayProteinG).toBe(18)
    expect(state.records).toHaveLength(1)
    expect(state.records[0].recipe_title).toBe('Dal Chawal')
  })

  it('sets error on failure', async () => {
    mockFrom.mockReturnValue({ insert: () => Promise.resolve({ error: new Error('DB error') }) })
    await useCookedMealStore.getState().logCooked(mockRecipe(), 'u1', 'p1', 'Adi')
    expect(useCookedMealStore.getState().error).toBe('DB error')
    expect(useCookedMealStore.getState().records).toHaveLength(0)
  })
})
