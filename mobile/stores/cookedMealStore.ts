import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { CookedMealRecord, Recipe } from '../types'

interface CookedMealState {
  records: CookedMealRecord[]
  todayCalories: number
  todayProteinG: number
  isLoading: boolean
  error: string | null
  fetchToday: () => Promise<void>
  logCooked: (recipe: Recipe, userId: string, profileId: string, profileName: string) => Promise<void>
  reset: () => void
}

function startOfToday(): string {
  const d = new Date()
  d.setHours(0, 0, 0, 0)
  return d.toISOString()
}

export const useCookedMealStore = create<CookedMealState>((set, get) => ({
  records: [],
  todayCalories: 0,
  todayProteinG: 0,
  isLoading: false,
  error: null,

  fetchToday: async () => {
    set({ isLoading: true, error: null })
    try {
      const { data, error } = await supabase
        .from('cooked_meal_records')
        .select('*')
        .gte('cooked_at', startOfToday())
        .order('cooked_at', { ascending: false })
      if (error) throw error
      const records = data || []
      set({
        records,
        todayCalories: records.reduce((sum, r) => sum + r.calories, 0),
        todayProteinG: records.reduce((sum, r) => sum + r.protein_g, 0),
      })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  logCooked: async (recipe, userId, profileId, profileName) => {
    set({ error: null })
    try {
      const record = {
        id: crypto.randomUUID(),
        user_id: userId,
        cooked_at: new Date().toISOString(),
        profile_id: profileId,
        profile_name_snapshot: profileName,
        recipe_title: recipe.title,
        recipe_ingredients: recipe.ingredients,
        consumptions: [],
        warnings: [],
        calories: recipe.calories,
        protein_g: recipe.protein,
        carbs_g: recipe.carbs,
        fat_g: recipe.fat,
        fiber_g: recipe.fiber,
      }
      const { error } = await supabase.from('cooked_meal_records').insert(record)
      if (error) throw error
      const prev = get()
      set({
        records: [record as unknown as CookedMealRecord, ...prev.records],
        todayCalories: prev.todayCalories + recipe.calories,
        todayProteinG: prev.todayProteinG + recipe.protein,
      })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },

  reset: () => set({ records: [], todayCalories: 0, todayProteinG: 0, isLoading: false, error: null }),
}))
