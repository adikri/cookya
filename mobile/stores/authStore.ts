import { create } from 'zustand'
import { supabase } from '../services/supabase'
import { usePantryStore } from './pantryStore'
import { useGroceryStore } from './groceryStore'
import { useProfileStore } from './profileStore'
import { useSavedRecipeStore } from './savedRecipeStore'
import { useCookedMealStore } from './cookedMealStore'
import { useWeeklyPlanStore } from './weeklyPlanStore'

interface AuthState {
  isLoading: boolean
  isSignedIn: boolean
  isNewUser: boolean
  email: string | null
  error: string | null
  signUp: (email: string, password: string) => Promise<void>
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
  checkSession: () => Promise<void>
  clearNewUser: () => void
}

export const useAuthStore = create<AuthState>((set) => ({
  isLoading: true,
  isSignedIn: false,
  isNewUser: false,
  email: null,
  error: null,

  signUp: async (email: string, password: string) => {
    set({ isLoading: true, error: null })
    try {
      const { error } = await supabase.auth.signUp({ email, password })
      if (error) throw error
      set({ isSignedIn: true, isNewUser: true, email })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  signIn: async (email: string, password: string) => {
    set({ isLoading: true, error: null })
    try {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) throw error
      set({ isSignedIn: true, email })
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  signOut: async () => {
    set({ isLoading: true, error: null })
    try {
      await supabase.auth.signOut()
      set({ isSignedIn: false, email: null })
      // Clear all per-user data so the next signed-in user doesn't see stale state.
      // Without this, partner saw Adi's profile/pantry/etc. after he signed out and she signed in.
      usePantryStore.getState().reset()
      useGroceryStore.getState().reset()
      useProfileStore.getState().reset()
      useSavedRecipeStore.getState().reset()
      useCookedMealStore.getState().reset()
      useWeeklyPlanStore.getState().reset()
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

  clearNewUser: () => set({ isNewUser: false }),

  checkSession: async () => {
    set({ isLoading: true })
    try {
      const { data } = await supabase.auth.getSession()
      if (data.session?.user) {
        set({ isSignedIn: true, email: data.session.user.email || null })
      }
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },
}))
