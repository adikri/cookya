import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { generateId } from '../services/id'
import { UserProfile } from '../types'

interface ProfileState {
  profile: UserProfile | null
  isLoading: boolean
  error: string | null
  fetchProfile: () => Promise<void>
  upsertProfile: (updates: Partial<Omit<UserProfile, 'id' | 'user_id' | 'created_at' | 'updated_at'>>) => Promise<void>
  reset: () => void
}

export const useProfileStore = create<ProfileState>((set, get) => ({
  profile: null,
  isLoading: false,
  error: null,

  fetchProfile: async () => {
    set({ isLoading: true, error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle()
      if (error) throw error
      set({ profile: data })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  upsertProfile: async (updates) => {
    set({ error: null })
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) throw new Error('Not authenticated')
      const existing = get().profile
      const now = new Date().toISOString()
      const record: Partial<UserProfile> = {
        ...(existing ?? { id: generateId(), created_at: now }),
        ...updates,
        user_id: user.id,
        updated_at: now,
      }
      const { data, error } = await supabase
        .from('profiles')
        .upsert(record, { onConflict: 'user_id' })
        .select()
      if (error) throw error
      if (data?.[0]) set({ profile: data[0] })
    } catch (err) {
      set({ error: (err as Error).message })
    }
  },

  reset: () => set({ profile: null, isLoading: false, error: null }),
}))
