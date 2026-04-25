import { useEffect, useState } from 'react'
import { View, Text, ScrollView, TouchableOpacity, ActivityIndicator, Alert } from 'react-native'
import { useRouter } from 'expo-router'
import { usePantryStore } from '../../stores/pantryStore'
import { useGroceryStore } from '../../stores/groceryStore'
import { useAuthStore } from '../../stores/authStore'
import { generateRecipe } from '../../services/recipeService'
import { Recipe } from '../../types'
import { SectionHeader } from '../../components/SectionHeader'
import { ManagementCard } from '../../components/ManagementCard'
import { colors, spacing, radius, typography } from '../../theme'

export default function HomeScreen() {
  const router = useRouter()
  const { items: pantryItems, fetchItems: fetchPantry } = usePantryStore()
  const { items: groceryItems, fetchItems: fetchGrocery } = useGroceryStore()
  const { email } = useAuthStore()
  const [recipe, setRecipe] = useState<Recipe | null>(null)
  const [isGenerating, setIsGenerating] = useState(false)

  const greeting = email ? email.split('@')[0] : 'there'

  useEffect(() => {
    fetchPantry()
    fetchGrocery()
  }, [])

  const handleGenerateRecipe = async () => {
    if (pantryItems.length === 0) {
      Alert.alert('Pantry is empty', 'Add some items to your pantry first.')
      return
    }
    setIsGenerating(true)
    try {
      const result = await generateRecipe(pantryItems)
      setRecipe(result)
    } catch (err) {
      Alert.alert('Error', (err as Error).message)
    } finally {
      setIsGenerating(false)
    }
  }

  const cookSubtitle = pantryItems.length === 0
    ? 'Build your pantry first, then generate recipes around what you already have.'
    : 'Use your pantry as the base and type extra ingredients only when needed.'

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.background }}>
      <View style={{ padding: spacing.lg, gap: spacing.xl }}>

        {/* Greeting */}
        <Text style={[typography.title2, { color: colors.textPrimary }]}>
          What's cooking {greeting}?!
        </Text>

        {/* H2: Nutrition progress card — Slice H2 (ProfileStore + CookedMealStore) */}

        {/* H3: Best Next Step — Slice H3 (HomeRecommendationEngine) */}

        {/* Let's Cook */}
        <View style={{ gap: spacing.md }}>
          <SectionHeader title="Let's Cook" subtitle={cookSubtitle} />
          <TouchableOpacity
            onPress={handleGenerateRecipe}
            disabled={isGenerating}
            activeOpacity={0.8}
            style={{
              padding: spacing.lg,
              borderRadius: 18,
              backgroundColor: colors.primary + '1F',
            }}
          >
            <View style={{ flexDirection: 'row', alignItems: 'flex-start', gap: spacing.md }}>
              <View style={{ flex: 1, gap: spacing.xs }}>
                <Text style={[typography.headline, { color: colors.textPrimary }]}>
                  🍴  Cook from pantry
                </Text>
                <Text style={[typography.subheadline, { color: colors.textSecondary }]}>
                  Select what you already have and let Cookya build tonight's meal around it.
                </Text>
              </View>
              {isGenerating
                ? <ActivityIndicator color={colors.primary} style={{ alignSelf: 'center' }} />
                : <Text style={{ color: colors.primary, fontSize: 22, alignSelf: 'center' }}>›</Text>
              }
            </View>
            {pantryItems.length > 0 && (
              <View style={{ marginTop: spacing.md }}>
                <View style={{
                  alignSelf: 'flex-start',
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: spacing.xs,
                  paddingHorizontal: spacing.md,
                  paddingVertical: spacing.xs,
                  backgroundColor: colors.primary + '1F',
                  borderRadius: radius.chip,
                }}>
                  <Text style={[typography.caption, { color: colors.primary, fontWeight: '600' }]}>
                    ✨  {pantryItems.length} items in pantry
                  </Text>
                </View>
              </View>
            )}
          </TouchableOpacity>

          {recipe && <RecipeCard recipe={recipe} />}
        </View>

        {/* H4: Attention Needed — Slice H4 (expiry filters on pantryStore) */}

        {/* H5: Cook Faster — Slice H5 (CookedMealStore + RecipeStore) */}

        {/* Kitchen Management */}
        <View style={{ gap: spacing.md }}>
          <SectionHeader
            title="Kitchen Management"
            subtitle="Keep pantry and grocery up to date without losing focus on cooking."
          />
          <View style={{ flexDirection: 'row', gap: spacing.lg }}>
            <ManagementCard
              title="Pantry"
              subtitle={pantryItems.length === 0 ? 'No items yet' : `${pantryItems.length} items available`}
              detail="Manage ingredients at home"
              icon="🥫"
              onPress={() => router.push('/(tabs)/pantry')}
            />
            <ManagementCard
              title="Grocery"
              subtitle={groceryItems.length === 0 ? 'Nothing on your list' : `${groceryItems.length} items on your list`}
              detail="Track what to buy next"
              icon="🛒"
              onPress={() => router.push('/(tabs)/grocery')}
            />
          </View>
        </View>

      </View>
    </ScrollView>
  )
}

function RecipeCard({ recipe }: { recipe: Recipe }) {
  return (
    <View style={{
      backgroundColor: colors.surface,
      padding: spacing.lg,
      borderRadius: radius.card,
      gap: spacing.md,
    }}>
      <Text style={[typography.headline, { color: colors.textPrimary }]}>{recipe.title}</Text>

      <View style={{ gap: spacing.xs }}>
        <Text style={[typography.caption, { color: colors.textSecondary, fontWeight: '600' }]}>
          INGREDIENTS
        </Text>
        {recipe.ingredients.map((ing, idx) => (
          <Text key={idx} style={[typography.subheadline, { color: colors.textSecondary }]}>
            • {ing.name} ({ing.quantity})
          </Text>
        ))}
      </View>

      <View style={{ gap: spacing.xs }}>
        <Text style={[typography.caption, { color: colors.textSecondary, fontWeight: '600' }]}>
          INSTRUCTIONS
        </Text>
        {recipe.instructions.map((inst, idx) => (
          <Text key={idx} style={[typography.subheadline, { color: colors.textSecondary }]}>
            {idx + 1}. {inst}
          </Text>
        ))}
      </View>

      <View style={{
        flexDirection: 'row',
        justifyContent: 'space-around',
        paddingTop: spacing.md,
        borderTopWidth: 1,
        borderTopColor: colors.border,
      }}>
        {([
          { label: 'Calories', value: recipe.calories, unit: '' },
          { label: 'Protein', value: recipe.protein, unit: 'g' },
          { label: 'Carbs', value: recipe.carbs, unit: 'g' },
          { label: 'Fat', value: recipe.fat, unit: 'g' },
        ] as const).map(({ label, value, unit }) => (
          <View key={label} style={{ alignItems: 'center', gap: spacing.xs }}>
            <Text style={[typography.caption, { color: colors.textSecondary }]}>{label}</Text>
            <Text style={[typography.headline, { color: colors.textPrimary }]}>{value}{unit}</Text>
          </View>
        ))}
      </View>
    </View>
  )
}
