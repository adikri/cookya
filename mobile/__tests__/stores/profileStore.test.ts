import { useProfileStore } from '../../stores/profileStore'

jest.mock('../../services/supabase', () => ({
  supabase: { from: jest.fn(), auth: { getUser: jest.fn() } },
}))

import { supabase } from '../../services/supabase'
const mockFrom = supabase.from as jest.Mock
const mockGetUser = supabase.auth.getUser as jest.Mock

const initialState = { profile: null, isLoading: false, error: null }

const mockProfile = () => ({
  id: 'profile-1', user_id: 'u1', name: 'Adi', age: 30,
  weight_kg: 75, height_cm: 175, is_vegetarian: false,
  avoid_food_items: [], nutrition_goals: null,
  created_at: '2026-01-01T00:00:00Z', updated_at: '2026-01-01T00:00:00Z',
})

beforeEach(() => {
  useProfileStore.setState(initialState)
  jest.clearAllMocks()
})

describe('fetchProfile', () => {
  it('sets profile on success', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'u1' } } })
    const profile = mockProfile()
    mockFrom.mockReturnValue({
      select: () => ({ eq: () => ({ maybeSingle: () => Promise.resolve({ data: profile, error: null }) }) }),
    })
    await useProfileStore.getState().fetchProfile()
    expect(useProfileStore.getState().profile).toEqual(profile)
  })

  it('sets profile to null when not found', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'u1' } } })
    mockFrom.mockReturnValue({
      select: () => ({ eq: () => ({ maybeSingle: () => Promise.resolve({ data: null, error: null }) }) }),
    })
    await useProfileStore.getState().fetchProfile()
    expect(useProfileStore.getState().profile).toBeNull()
  })

  it('sets error when not authenticated', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } })
    await useProfileStore.getState().fetchProfile()
    expect(useProfileStore.getState().error).toBe('Not authenticated')
  })
})

describe('upsertProfile', () => {
  it('updates local profile on success', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'u1' } } })
    const updated = { ...mockProfile(), name: 'Aditya' }
    mockFrom.mockReturnValue({
      upsert: () => ({ select: () => Promise.resolve({ data: [updated], error: null }) }),
    })
    await useProfileStore.getState().upsertProfile({ name: 'Aditya' })
    expect(useProfileStore.getState().profile?.name).toBe('Aditya')
  })

  it('sets error when not authenticated', async () => {
    mockGetUser.mockResolvedValue({ data: { user: null } })
    await useProfileStore.getState().upsertProfile({ name: 'Adi' })
    expect(useProfileStore.getState().error).toBe('Not authenticated')
  })
})
