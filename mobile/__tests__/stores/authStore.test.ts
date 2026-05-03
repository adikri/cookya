import { useAuthStore } from '../../stores/authStore'
import { usePantryStore } from '../../stores/pantryStore'
import { useGroceryStore } from '../../stores/groceryStore'
import { useProfileStore } from '../../stores/profileStore'
import { useSavedRecipeStore } from '../../stores/savedRecipeStore'
import { useCookedMealStore } from '../../stores/cookedMealStore'
import { useWeeklyPlanStore } from '../../stores/weeklyPlanStore'

jest.mock('../../services/supabase', () => ({
  supabase: {
    auth: {
      getSession: jest.fn(),
      signUp: jest.fn(),
      signInWithPassword: jest.fn(),
      signOut: jest.fn(),
    },
  },
}))

import { supabase } from '../../services/supabase'
const mockAuth = supabase.auth as jest.Mocked<typeof supabase.auth>

const initialState = { isLoading: true, isSignedIn: false, isNewUser: false, email: null, error: null }

beforeEach(() => {
  useAuthStore.setState(initialState)
  jest.clearAllMocks()
})

describe('checkSession', () => {
  it('sets isSignedIn and email when session exists', async () => {
    mockAuth.getSession.mockResolvedValue({
      data: { session: { user: { email: 'adi@example.com' } } },
      error: null,
    } as any)

    await useAuthStore.getState().checkSession()

    expect(useAuthStore.getState().isSignedIn).toBe(true)
    expect(useAuthStore.getState().email).toBe('adi@example.com')
    expect(useAuthStore.getState().isLoading).toBe(false)
  })

  it('keeps isSignedIn false when no session', async () => {
    mockAuth.getSession.mockResolvedValue({
      data: { session: null },
      error: null,
    } as any)

    await useAuthStore.getState().checkSession()

    expect(useAuthStore.getState().isSignedIn).toBe(false)
    expect(useAuthStore.getState().email).toBeNull()
    expect(useAuthStore.getState().isLoading).toBe(false)
  })

  it('sets error and clears loading on failure', async () => {
    mockAuth.getSession.mockRejectedValue(new Error('Network failure'))

    await useAuthStore.getState().checkSession()

    expect(useAuthStore.getState().isSignedIn).toBe(false)
    expect(useAuthStore.getState().error).toBe('Network failure')
    expect(useAuthStore.getState().isLoading).toBe(false)
  })
})

describe('signIn', () => {
  it('sets isSignedIn and email on success', async () => {
    mockAuth.signInWithPassword.mockResolvedValue({ error: null } as any)

    await useAuthStore.getState().signIn('adi@example.com', 'password123')

    expect(useAuthStore.getState().isSignedIn).toBe(true)
    expect(useAuthStore.getState().email).toBe('adi@example.com')
    expect(useAuthStore.getState().isLoading).toBe(false)
  })

  it('sets error on invalid credentials', async () => {
    mockAuth.signInWithPassword.mockResolvedValue({
      error: new Error('Invalid login credentials'),
    } as any)

    await useAuthStore.getState().signIn('bad@example.com', 'wrong')

    expect(useAuthStore.getState().isSignedIn).toBe(false)
    expect(useAuthStore.getState().error).toBe('Invalid login credentials')
    expect(useAuthStore.getState().isLoading).toBe(false)
  })
})

describe('signUp', () => {
  it('sets isSignedIn and isNewUser on successful registration', async () => {
    mockAuth.signUp.mockResolvedValue({ error: null } as any)

    await useAuthStore.getState().signUp('new@example.com', 'password123')

    expect(useAuthStore.getState().isSignedIn).toBe(true)
    expect(useAuthStore.getState().isNewUser).toBe(true)
    expect(useAuthStore.getState().email).toBe('new@example.com')
  })

  it('clearNewUser resets isNewUser to false', async () => {
    useAuthStore.setState({ isNewUser: true })
    useAuthStore.getState().clearNewUser()
    expect(useAuthStore.getState().isNewUser).toBe(false)
  })

  it('sets error when email already registered', async () => {
    mockAuth.signUp.mockResolvedValue({
      error: new Error('User already registered'),
    } as any)

    await useAuthStore.getState().signUp('existing@example.com', 'password123')

    expect(useAuthStore.getState().isSignedIn).toBe(false)
    expect(useAuthStore.getState().error).toBe('User already registered')
  })
})

describe('signOut', () => {
  it('clears session state', async () => {
    useAuthStore.setState({ isSignedIn: true, email: 'adi@example.com', isLoading: false, error: null })
    mockAuth.signOut.mockResolvedValue({ error: null } as any)

    await useAuthStore.getState().signOut()

    expect(useAuthStore.getState().isSignedIn).toBe(false)
    expect(useAuthStore.getState().email).toBeNull()
  })

  // Regression: without this, partner saw Adi's profile/pantry/etc. after he signed out and she signed in.
  it('resets all per-user data stores so the next signed-in user does not see stale data', async () => {
    usePantryStore.setState({ items: [{ id: '1' } as any] })
    useGroceryStore.setState({ items: [{ id: '2' } as any] })
    useProfileStore.setState({ profile: { id: '3' } as any })
    useSavedRecipeStore.setState({ recipes: [{ id: '4' } as any] })
    useCookedMealStore.setState({ records: [{ id: '5' } as any], todayCalories: 800, todayProteinG: 50 })
    useWeeklyPlanStore.setState({ meals: [{ id: '6' } as any] })

    useAuthStore.setState({ isSignedIn: true, email: 'adi@example.com', isLoading: false, error: null })
    mockAuth.signOut.mockResolvedValue({ error: null } as any)

    await useAuthStore.getState().signOut()

    expect(usePantryStore.getState().items).toEqual([])
    expect(useGroceryStore.getState().items).toEqual([])
    expect(useProfileStore.getState().profile).toBeNull()
    expect(useSavedRecipeStore.getState().recipes).toEqual([])
    expect(useCookedMealStore.getState().records).toEqual([])
    expect(useCookedMealStore.getState().todayCalories).toBe(0)
    expect(useCookedMealStore.getState().todayProteinG).toBe(0)
    expect(useWeeklyPlanStore.getState().meals).toEqual([])
  })
})
