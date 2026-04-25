import { useEffect } from 'react'
import { View, FlatList, TouchableOpacity, Text } from 'react-native'
import { useWeeklyPlanStore } from '../../stores/weeklyPlanStore'
import { useSavedRecipeStore } from '../../stores/savedRecipeStore'
import { useGroceryStore } from '../../stores/groceryStore'
import { useAuthStore } from '../../stores/authStore'
import { colors, spacing, radius, typography } from '../../theme'
import { SectionHeader } from '../../components/SectionHeader'

export default function PlanScreen() {
  const { meals, fetchMeals, removeMeal, clearAll, isLoading, error } = useWeeklyPlanStore()
  const { recipes: savedRecipes, fetchRecipes } = useSavedRecipeStore()
  const { addItem: addGroceryItem } = useGroceryStore()
  const { email } = useAuthStore()

  useEffect(() => {
    fetchMeals()
    fetchRecipes()
  }, [])

  const plannedIds = new Set(meals.map(m => m.saved_recipe_id))
  const unplanned = savedRecipes.filter(r => !plannedIds.has(r.id))

  const handleAddAllToGrocery = async () => {
    const { data: { user } } = await (await import('../../services/supabase')).supabase.auth.getUser()
    if (!user) return
    const seen = new Set<string>()
    for (const meal of meals) {
      const saved = savedRecipes.find(r => r.id === meal.saved_recipe_id)
      if (!saved) continue
      for (const ing of saved.recipe.ingredients) {
        const key = ing.name.toLowerCase().trim()
        if (seen.has(key)) continue
        seen.add(key)
        await addGroceryItem(ing.name, ing.quantity, 'other', `For ${saved.recipe.title}`)
      }
    }
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <FlatList
        data={meals}
        keyExtractor={(item) => item.id}
        ListHeaderComponent={
          <View style={{ padding: spacing.lg, gap: spacing.xl }}>
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={[typography.title2, { color: colors.textPrimary }]}>
                Weekly Plan ({meals.length}/7)
              </Text>
              {meals.length > 0 && (
                <TouchableOpacity onPress={clearAll}>
                  <Text style={[typography.caption, { color: colors.danger, fontWeight: '600' }]}>Clear All</Text>
                </TouchableOpacity>
              )}
            </View>

            {meals.length > 0 && (
              <TouchableOpacity
                onPress={handleAddAllToGrocery}
                style={{
                  backgroundColor: colors.primary, padding: spacing.md,
                  borderRadius: radius.button, alignItems: 'center',
                }}
              >
                <Text style={[typography.headline, { color: colors.background }]}>
                  Add All Ingredients to Grocery
                </Text>
              </TouchableOpacity>
            )}

            {unplanned.length > 0 && (
              <View style={{ gap: spacing.md }}>
                <SectionHeader title="Add to Plan" subtitle="From your saved recipes" />
                {unplanned.map(r => (
                  <View key={r.id} style={{
                    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
                    backgroundColor: colors.surface, padding: spacing.md, borderRadius: radius.button,
                  }}>
                    <View style={{ flex: 1 }}>
                      <Text style={[typography.subheadline, { color: colors.textPrimary }]}>{r.recipe.title}</Text>
                      <Text style={[typography.caption, { color: colors.textTertiary }]}>
                        {r.recipe.protein}g protein
                      </Text>
                    </View>
                  </View>
                ))}
              </View>
            )}

            {meals.length > 0 && (
              <SectionHeader title="This Week" subtitle="" />
            )}
          </View>
        }
        renderItem={({ item }) => (
          <View style={{
            flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
            paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
            borderBottomWidth: 1, borderBottomColor: colors.border,
          }}>
            <Text style={[typography.headline, { color: colors.textPrimary, flex: 1 }]}>
              {item.recipe_title}
            </Text>
            <TouchableOpacity
              onPress={() => removeMeal(item.id)}
              style={{ padding: spacing.sm, backgroundColor: colors.danger + '1F', borderRadius: radius.button }}
            >
              <Text style={[typography.caption, { color: colors.danger, fontWeight: '600' }]}>Remove</Text>
            </TouchableOpacity>
          </View>
        )}
        ListEmptyComponent={
          !isLoading && unplanned.length === 0 ? (
            <View style={{ padding: spacing.xl, alignItems: 'center' }}>
              <Text style={[typography.subheadline, { color: colors.textTertiary }]}>
                Save some recipes first, then plan your week.
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
