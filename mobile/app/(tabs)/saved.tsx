import { useEffect } from 'react'
import { View, FlatList, TouchableOpacity, Text } from 'react-native'
import { useSavedRecipeStore } from '../../stores/savedRecipeStore'
import { useWeeklyPlanStore } from '../../stores/weeklyPlanStore'
import { useAuthStore } from '../../stores/authStore'
import { SavedRecipe } from '../../types'
import { colors, spacing, radius, typography } from '../../theme'

export default function SavedScreen() {
  const { recipes, fetchRecipes, toggleFavorite, deleteRecipe, isLoading, error } = useSavedRecipeStore()
  const { addMeal, meals } = useWeeklyPlanStore()
  const { email } = useAuthStore()

  useEffect(() => {
    fetchRecipes()
  }, [])

  const handleAddToPlan = async (recipe: SavedRecipe) => {
    const { data: { user } } = await (await import('../../services/supabase')).supabase.auth.getUser()
    if (!user) return
    await addMeal(recipe, user.id)
  }

  const isInPlan = (recipeId: string) => meals.some(m => m.saved_recipe_id === recipeId)

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <FlatList
        data={recipes}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={{
            padding: spacing.lg,
            borderBottomWidth: 1,
            borderBottomColor: colors.border,
            gap: spacing.sm,
          }}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <View style={{ flex: 1 }}>
                <Text style={[typography.headline, { color: colors.textPrimary }]}>
                  {item.recipe.title}
                </Text>
                <Text style={[typography.caption, { color: colors.textSecondary, marginTop: spacing.xs }]}>
                  {item.recipe.protein}g protein · {item.recipe.calories} cal
                </Text>
              </View>
              <TouchableOpacity onPress={() => toggleFavorite(item.id, item.is_favorite)} style={{ padding: spacing.xs }}>
                <Text style={{ fontSize: 20 }}>{item.is_favorite ? '⭐' : '☆'}</Text>
              </TouchableOpacity>
            </View>

            <View style={{ flexDirection: 'row', gap: spacing.sm }}>
              <TouchableOpacity
                onPress={() => handleAddToPlan(item)}
                disabled={isInPlan(item.id)}
                style={{
                  flex: 1, padding: spacing.sm, borderRadius: radius.button, alignItems: 'center',
                  backgroundColor: isInPlan(item.id) ? colors.surface : colors.primary + '1F',
                  borderWidth: 1, borderColor: isInPlan(item.id) ? colors.border : colors.primary,
                }}
              >
                <Text style={[typography.caption, { color: isInPlan(item.id) ? colors.textTertiary : colors.primary, fontWeight: '600' }]}>
                  {isInPlan(item.id) ? 'In Plan' : '+ Add to Plan'}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => deleteRecipe(item.id)}
                style={{
                  padding: spacing.sm, paddingHorizontal: spacing.md,
                  borderRadius: radius.button, backgroundColor: colors.danger + '1F',
                }}
              >
                <Text style={[typography.caption, { color: colors.danger, fontWeight: '600' }]}>Delete</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListEmptyComponent={
          !isLoading ? (
            <View style={{ padding: spacing.xl, alignItems: 'center' }}>
              <Text style={[typography.subheadline, { color: colors.textTertiary }]}>
                No saved recipes yet. Generate a recipe and tap Save.
              </Text>
            </View>
          ) : null
        }
      />
      {error ? (
        <View style={{ padding: spacing.md, backgroundColor: colors.danger + '1F' }}>
          <Text style={[typography.caption, { color: colors.danger }]}>{error}</Text>
        </View>
      ) : null}
    </View>
  )
}
