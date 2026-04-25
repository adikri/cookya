import { useGroceryStore } from '../../stores/groceryStore'

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
  quantity_text: '1 cup',
  category: 'vegetables',
  note: null,
  source: 'manual',
  reason_recipes: [],
  created_at: '2026-01-01T00:00:00Z',
})

beforeEach(() => {
  useGroceryStore.setState(initialState)
  jest.clearAllMocks()
})

describe('fetchItems', () => {
  it('sets items on success', async () => {
    const items = [mockItem('1', 'Tomatoes'), mockItem('2', 'Spinach')]
    mockFrom.mockReturnValue({
      select: () => ({ order: () => Promise.resolve({ data: items, error: null }) }),
    })

    await useGroceryStore.getState().fetchItems()

    expect(useGroceryStore.getState().items).toEqual(items)
    expect(useGroceryStore.getState().isLoading).toBe(false)
  })

  it('sets error on failure', async () => {
    mockFrom.mockReturnValue({
      select: () => ({ order: () => Promise.resolve({ data: null, error: new Error('Network error') }) }),
    })

    await useGroceryStore.getState().fetchItems()

    expect(useGroceryStore.getState().items).toEqual([])
    expect(useGroceryStore.getState().error).toBe('Network error')
  })
})

describe('addItem', () => {
  it('prepends new item with note', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'user1' } } })
    const newItem = mockItem('new', 'Coriander')
    mockFrom.mockReturnValue({
      insert: () => ({ select: () => Promise.resolve({ data: [newItem], error: null }) }),
    })

    await useGroceryStore.getState().addItem('Coriander', '1 bunch', 'vegetables', 'fresh')

    expect(useGroceryStore.getState().items[0]).toEqual(newItem)
  })

  it('prepends new item without note', async () => {
    mockGetUser.mockResolvedValue({ data: { user: { id: 'user1' } } })
    const newItem = mockItem('new', 'Garlic')
    mockFrom.mockReturnValue({
      insert: () => ({ select: () => Promise.resolve({ data: [newItem], error: null }) }),
    })

    await useGroceryStore.getState().addItem('Garlic', '6 cloves', 'vegetables')

    expect(useGroceryStore.getState().items[0]).toEqual(newItem)
  })
})

describe('markPurchased', () => {
  it('removes item from grocery list on success', async () => {
    const item = mockItem('1', 'Tomatoes')
    useGroceryStore.setState({ items: [item, mockItem('2', 'Spinach')] })

    mockFrom
      .mockReturnValueOnce({
        delete: () => ({ eq: () => Promise.resolve({ error: null }) }),
      })
      .mockReturnValueOnce({
        insert: () => Promise.resolve({ error: null }),
      })

    await useGroceryStore.getState().markPurchased('1', item)

    const { items } = useGroceryStore.getState()
    expect(items).toHaveLength(1)
    expect(items[0].id).toBe('2')
  })

  it('sets error and keeps item if grocery delete fails', async () => {
    const item = mockItem('1', 'Tomatoes')
    useGroceryStore.setState({ items: [item] })

    mockFrom.mockReturnValue({
      delete: () => ({ eq: () => Promise.resolve({ error: new Error('Delete failed') }) }),
    })

    await useGroceryStore.getState().markPurchased('1', item)

    expect(useGroceryStore.getState().items).toEqual([item])
    expect(useGroceryStore.getState().error).toBe('Delete failed')
  })
})

describe('deleteItem', () => {
  it('removes correct item from list', async () => {
    useGroceryStore.setState({ items: [mockItem('1', 'Tomatoes'), mockItem('2', 'Spinach')] })

    mockFrom.mockReturnValue({
      delete: () => ({ eq: () => Promise.resolve({ error: null }) }),
    })

    await useGroceryStore.getState().deleteItem('1')

    const { items } = useGroceryStore.getState()
    expect(items).toHaveLength(1)
    expect(items[0].id).toBe('2')
  })
})
