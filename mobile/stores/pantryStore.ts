import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { PantryItem } from '../types'

interface PantryState {
  items: PantryItem[]
  isLoading: boolean
  error: string | null
  fetchItems: () => Promise<void>
  addItem: (name: string, quantity: string, category: string) => Promise<void>
  deleteItem: (id: string) => Promise<void>
}

export const usePantryStore = create<PantryState>((set, get) => ({
  items: [],
  isLoading: false,
  error: null,

  fetchItems: async () => {
    set({ isLoading: true, error: null })
    try {
      const { data, error } = await supabase
        .from('pantry_items')
        .select('*')
        .order('updated_at', { ascending: false })
      if (error) throw error
      set({ items: data || [] })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  addItem: async (name: string, quantity: string, category: string) => {
    set({ error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')
      const { data, error } = await supabase
        .from('pantry_items')
        .insert({
          id: crypto.randomUUID(),
          user_id: user.id,
          name,
          quantity_text: quantity,
          category,
          updated_at: new Date().toISOString(),
        })
        .select()
      if (error) throw error
      if (data) {
        set({ items: [data[0], ...get().items] })
      }
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },

  deleteItem: async (id: string) => {
    set({ error: null })
    try {
      const { error } = await supabase
        .from('pantry_items')
        .delete()
        .eq('id', id)
      if (error) throw error
      set({ items: get().items.filter((item) => item.id !== id) })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },
}))
