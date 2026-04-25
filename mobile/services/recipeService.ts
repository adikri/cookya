import { Recipe, PantryItem } from '../types'

export async function generateRecipe(pantryItems: PantryItem[]): Promise<Recipe> {
  const workerUrl = process.env.EXPO_PUBLIC_WORKER_URL || ''
  const workerToken = process.env.EXPO_PUBLIC_WORKER_TOKEN || ''

  if (!workerUrl || !workerToken) {
    throw new Error('Worker URL or token not configured. Update .env file.')
  }
  const response = await fetch(`${workerUrl}/v1/recipes/generate`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${workerToken}`,
    },
    body: JSON.stringify({
      pantryItems: pantryItems.map((item) => ({
        name: item.name,
        quantity_text: item.quantity_text,
        category: item.category,
      })),
      manualIngredients: [],
      difficulty: 'medium',
      servings: 2,
    }),
  })

  if (!response.ok) {
    throw new Error(`Recipe generation failed: ${response.statusText}`)
  }

  return response.json()
}
