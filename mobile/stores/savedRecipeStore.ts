import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { generateId } from '../services/id'
import { SavedRecipe, Recipe } from '../types'

interface SavedRecipeState {
  recipes: SavedRecipe[]
  isLoading: boolean
  error: string | null
  fetchRecipes: () => Promise<void>
  saveRecipe: (recipe: Recipe, userId: string, profileId: string, profileName: string) => Promise<void>
  toggleFavorite: (id: string, current: boolean) => Promise<void>
  deleteRecipe: (id: string) => Promise<void>
  reset: () => void
}

export const useSavedRecipeStore = create<SavedRecipeState>((set, get) => ({
  recipes: [],
  isLoading: false,
  error: null,

  fetchRecipes: async () => {
    set({ isLoading: true, error: null })
    try {
      const { data, error } = await supabase
        .from('saved_recipes')
        .select('*')
        .order('saved_at', { ascending: false })
      if (error) throw error
      set({ recipes: data || [] })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  saveRecipe: async (recipe, userId, profileId, profileName) => {
    set({ error: null })
    try {
      const existing = get().recipes.find(r => r.recipe.id === recipe.id)
      if (existing) return
      const { data, error } = await supabase
        .from('saved_recipes')
        .insert({
          id: generateId(),
          user_id: userId,
          recipe,
          profile_id: profileId,
          profile_name_snapshot: profileName,
          saved_at: new Date().toISOString(),
          is_favorite: false,
        })
        .select()
      if (error) throw error
      if (data) set({ recipes: [data[0], ...get().recipes] })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },

  toggleFavorite: async (id, current) => {
    set({ recipes: get().recipes.map(r => r.id === id ? { ...r, is_favorite: !current } : r) })
    try {
      const { error } = await supabase
        .from('saved_recipes')
        .update({ is_favorite: !current })
        .eq('id', id)
      if (error) throw error
    } catch (err) {
      set({ recipes: get().recipes.map(r => r.id === id ? { ...r, is_favorite: current } : r) })
      set({ error: (err as Error).message })
    }
  },

  deleteRecipe: async (id) => {
    const prev = get().recipes
    set({ recipes: prev.filter(r => r.id !== id) })
    try {
      const { error } = await supabase.from('saved_recipes').delete().eq('id', id)
      if (error) throw error
    } catch (err) {
      set({ recipes: prev, error: (err as Error).message })
    }
  },

  reset: () => set({ recipes: [], isLoading: false, error: null }),
}))
