import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { GroceryItem } from '../types'

interface GroceryState {
  items: GroceryItem[]
  isLoading: boolean
  error: string | null
  fetchItems: () => Promise<void>
  addItem: (name: string, quantity: string, category: string, note?: string) => Promise<void>
  markPurchased: (id: string, item: GroceryItem) => Promise<void>
  deleteItem: (id: string) => Promise<void>
}

export const useGroceryStore = create<GroceryState>((set, get) => ({
  items: [],
  isLoading: false,
  error: null,

  fetchItems: async () => {
    set({ isLoading: true, error: null })
    try {
      const { data, error } = await supabase
        .from('grocery_items')
        .select('*')
        .order('created_at', { ascending: false })
      if (error) throw error
      set({ items: data || [] })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  addItem: async (name: string, quantity: string, category: string, note?: string) => {
    set({ error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')
      const { data, error } = await supabase
        .from('grocery_items')
        .insert({
          id: crypto.randomUUID(),
          user_id: user.id,
          name,
          quantity_text: quantity,
          category,
          note: note || null,
          source: 'manual',
          reason_recipes: [],
          created_at: new Date().toISOString(),
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

  markPurchased: async (id: string, item: GroceryItem) => {
    set({ error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')

      const { error: deleteError } = await supabase
        .from('grocery_items')
        .delete()
        .eq('id', id)
      if (deleteError) throw deleteError

      const { error: insertError } = await supabase
        .from('pantry_items')
        .insert({
          id: crypto.randomUUID(),
          user_id: user.id,
          name: item.name,
          quantity_text: item.quantity_text,
          category: item.category,
          updated_at: new Date().toISOString(),
        })
      if (insertError) throw insertError

      set({ items: get().items.filter((i) => i.id !== id) })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },

  deleteItem: async (id: string) => {
    set({ error: null })
    try {
      const { error } = await supabase
        .from('grocery_items')
        .delete()
        .eq('id', id)
      if (error) throw error
      set({ items: get().items.filter((item) => item.id !== id) })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },
}))
