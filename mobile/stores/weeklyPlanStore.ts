import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { WeeklyPlanMeal, SavedRecipe } from '../types'

const MAX_MEALS = 7

interface WeeklyPlanState {
  meals: WeeklyPlanMeal[]
  isLoading: boolean
  error: string | null
  fetchMeals: () => Promise<void>
  addMeal: (savedRecipe: SavedRecipe, userId: string) => Promise<void>
  removeMeal: (id: string) => Promise<void>
  clearAll: () => Promise<void>
}

export const useWeeklyPlanStore = create<WeeklyPlanState>((set, get) => ({
  meals: [],
  isLoading: false,
  error: null,

  fetchMeals: async () => {
    set({ isLoading: true, error: null })
    try {
      const { data, error } = await supabase
        .from('weekly_plan_meals')
        .select('*')
        .order('added_at', { ascending: true })
      if (error) throw error
      set({ meals: data || [] })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  addMeal: async (savedRecipe, userId) => {
    const current = get().meals
    if (current.length >= MAX_MEALS) return
    if (current.some(m => m.saved_recipe_id === savedRecipe.id)) return
    set({ error: null })
    try {
      const meal = {
        id: crypto.randomUUID(),
        user_id: userId,
        saved_recipe_id: savedRecipe.id,
        recipe_title: savedRecipe.recipe.title,
        added_at: new Date().toISOString(),
      }
      const { error } = await supabase.from('weekly_plan_meals').insert(meal)
      if (error) throw error
      set({ meals: [...get().meals, meal] })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },

  removeMeal: async (id) => {
    const prev = get().meals
    set({ meals: prev.filter(m => m.id !== id) })
    try {
      const { error } = await supabase.from('weekly_plan_meals').delete().eq('id', id)
      if (error) throw error
    } catch (err) {
      set({ meals: prev, error: (err as Error).message })
    }
  },

  clearAll: async () => {
    const prev = get().meals
    set({ meals: [] })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')
      const { error } = await supabase.from('weekly_plan_meals').delete().eq('user_id', user.id)
      if (error) throw error
    } catch (err) {
      set({ meals: prev, error: (err as Error).message })
    }
  },
}))
