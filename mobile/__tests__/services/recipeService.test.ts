import { generateRecipe } from '../../services/recipeService'
import { PantryItem } from '../../types'

const pantryItems: PantryItem[] = [
  { id: '1', user_id: 'u1', name: 'Rice', quantity_text: '2 cups', category: 'grains', expiry_date: null, updated_at: '' },
  { id: '2', user_id: 'u1', name: 'Dal', quantity_text: '1 cup', category: 'legumes', expiry_date: null, updated_at: '' },
]

const mockRecipe = {
  id: 'r1',
  title: 'Dal Chawal',
  ingredients: [{ name: 'Rice', quantity: '2 cups' }, { name: 'Dal', quantity: '1 cup' }],
  instructions: ['Boil rice', 'Cook dal', 'Serve together'],
  calories: 450,
  protein: 18,
  carbs: 72,
  fat: 6,
  fiber: 8,
  difficulty: 'easy',
}

beforeEach(() => {
  jest.clearAllMocks()
  delete process.env.EXPO_PUBLIC_WORKER_URL
  delete process.env.EXPO_PUBLIC_WORKER_TOKEN
})

describe('generateRecipe', () => {
  it('throws when worker URL is missing', async () => {
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'token123'

    await expect(generateRecipe(pantryItems)).rejects.toThrow(
      'Worker URL or token not configured'
    )
  })

  it('throws when worker token is missing', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'

    await expect(generateRecipe(pantryItems)).rejects.toThrow(
      'Worker URL or token not configured'
    )
  })

  it('returns recipe on successful response', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'token123'

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockRecipe),
    })

    const result = await generateRecipe(pantryItems)
    expect(result).toEqual(mockRecipe)
  })

  it('sends pantry items in request body', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'token123'

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockRecipe),
    })

    await generateRecipe(pantryItems)

    const [, options] = (global.fetch as jest.Mock).mock.calls[0]
    const body = JSON.parse(options.body)
    expect(body.pantryItems).toHaveLength(2)
    expect(body.pantryItems[0].name).toBe('Rice')
    expect(body.pantryItems[1].name).toBe('Dal')
  })

  it('sends auth header with token', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'mytoken'

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockRecipe),
    })

    await generateRecipe(pantryItems)

    const [, options] = (global.fetch as jest.Mock).mock.calls[0]
    expect(options.headers['Authorization']).toBe('Bearer mytoken')
  })

  it('sends profile context when provided', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'token123'

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockRecipe),
    })

    const profile = {
      id: 'p1', user_id: 'u1', name: 'Adi', age: 30,
      weight_kg: 75, height_cm: 175, is_vegetarian: true,
      avoid_food_items: ['nuts'], nutrition_goals: null,
      created_at: '', updated_at: '',
    }

    await generateRecipe(pantryItems, profile)

    const [, options] = (global.fetch as jest.Mock).mock.calls[0]
    const body = JSON.parse(options.body)
    expect(body.profile.isVegetarian).toBe(true)
    expect(body.profile.avoidFoodItems).toEqual(['nuts'])
  })

  it('sends null profile when not provided', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'token123'

    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      json: () => Promise.resolve(mockRecipe),
    })

    await generateRecipe(pantryItems)

    const [, options] = (global.fetch as jest.Mock).mock.calls[0]
    const body = JSON.parse(options.body)
    expect(body.profile).toBeNull()
  })

  it('throws on non-ok response', async () => {
    process.env.EXPO_PUBLIC_WORKER_URL = 'https://worker.example.com'
    process.env.EXPO_PUBLIC_WORKER_TOKEN = 'token123'

    global.fetch = jest.fn().mockResolvedValue({
      ok: false,
      statusText: 'Internal Server Error',
    })

    await expect(generateRecipe(pantryItems)).rejects.toThrow(
      'Recipe generation failed: Internal Server Error'
    )
  })
})
