import { usePantryStore } from '../../stores/pantryStore'

jest.mock('../../services/supabase', () => ({
  supabase: {
    from: jest.fn(),
    auth: { getUser: jest.fn() },
  },
}))

import { supabase } from '../../services/supabase'
const mockFrom = supabase.from as jest.Mock
const mockGetUser = supabase.auth.getUser as jest.Mock

const initialState = { items: [], isLoading: false, error: null }

const mockItem = (id: string, name: string) => ({
  id,
  user_id: 'user1',
  name,
  quantity_text: '2 cups',
  category: 'grains',
  expiry_date: null,
  updated_at: '2026-01-01T00:00:00Z',
})

beforeEach(() => {
  usePantryStore.setState(initialState)
  jest.clearAllMocks()
})

describe('fetchItems', () => {
  it('sets items on success', async () => {
    const items = [mockItem('1', 'Rice'), mockItem('2', 'Dal')]
    mockFrom.mockReturnValue({
      select: () => ({ order: () => Promise.resolve({ data: items, error: null }) }),
    })

    await usePantryStore.getState().fetchItems()

    expect(usePantryStore.getState().items).toEqual(items)
    expect(usePantryStore.getState().isLoading).toBe(false)
    expect(usePantryStore.getState().error).toBeNull()
  })

  it('sets error and keeps items empty on failure', async () => {
    mockFrom.mockReturnValue({
      select: () => ({ order: () => Promise.resolve({ data: null, error: new Error('DB error') }) }),
    })

    await usePantryStore.getState().fetchItems()

    expect(usePantryStore.getState().items).toEqual([])
    expect(usePantryStore.getState().error).toBe('DB error')
    expect(usePantryStore.getState().isLoading).toBe(false)
  })

  it('sets isLoading false even when fetch succeeds', async () => {
    mockFrom.mockReturnValue({
      select: () => ({ order: () => Promise.resolve({ data: [], error: null }) }),
    })

    await usePantryStore.getState().fetchItems()

    expect(usePantryStore.getState().isLoading).toBe(false)
  })
})

describe('addItem', () => {
  it('prepends new item to existing list', async () => {
    const existing = mockItem('old', 'Onion')
    usePantryStore.setState({ items: [existing] })
    mockGetUser.mockResolvedValue({ data: { user: { id: 'user1' } } })

    const newItem = mockItem('new', 'Tomato')
    mockFrom.mockReturnValue({
      insert: () => ({ select: () => Promise.resolve({ data: [newItem], error: null }) }),
    })

    await usePantryStore.getState().addItem('Tomato', '2 cups', 'vegetables')

    const { items } = usePantryStore.getState()
    expect(items).toHaveLength(2)
    expect(items[0]).toEqual(newItem)
    expect(items[1]).toEqual(existing)
  })

  it('sets error on failure and does not change list', async () => {
    const existing = mockItem('1', 'Rice')
    usePantryStore.setState({ items: [existing] })
    mockGetUser.mockResolvedValue({ data: { user: { id: 'user1' } } })

    mockFrom.mockReturnValue({
      insert: () => ({ select: () => Promise.resolve({ data: null, error: new Error('Insert failed') }) }),
    })

    await usePantryStore.getState().addItem('Tomato', '2 cups', 'vegetables')

    expect(usePantryStore.getState().items).toEqual([existing])
    expect(usePantryStore.getState().error).toBe('Insert failed')
  })
})

describe('deleteItem', () => {
  it('removes the correct item from local state', async () => {
    usePantryStore.setState({ items: [mockItem('1', 'Rice'), mockItem('2', 'Dal')] })

    mockFrom.mockReturnValue({
      delete: () => ({ eq: () => Promise.resolve({ error: null }) }),
    })

    await usePantryStore.getState().deleteItem('1')

    const { items } = usePantryStore.getState()
    expect(items).toHaveLength(1)
    expect(items[0].id).toBe('2')
  })

  it('sets error and keeps list intact on failure', async () => {
    const items = [mockItem('1', 'Rice')]
    usePantryStore.setState({ items })

    mockFrom.mockReturnValue({
      delete: () => ({ eq: () => Promise.resolve({ error: new Error('Delete failed') }) }),
    })

    await usePantryStore.getState().deleteItem('1')

    expect(usePantryStore.getState().items).toEqual(items)
    expect(usePantryStore.getState().error).toBe('Delete failed')
  })
})
