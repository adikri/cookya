import { create } from 'zustand'
import { supabase } from '../services/supabase'

interface AuthState {
  isLoading: boolean
  isSignedIn: boolean
  email: string | null
  error: string | null
  signUp: (email: string, password: string) => Promise<void>
  signIn: (email: string, password: string) => Promise<void>
  signOut: () => Promise<void>
  checkSession: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set) => ({
  isLoading: true,
  isSignedIn: false,
  email: null,
  error: null,

  signUp: async (email: string, password: string) => {
    set({ isLoading: true, error: null })
    try {
      const { error } = await supabase.auth.signUp({ email, password })
      if (error) throw error
      set({ isSignedIn: true, email })
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
    } catch (err) {
      set({ error: (err as Error).message })
    } finally {
      set({ isLoading: false })
    }
  },

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
