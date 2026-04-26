import { useEffect, useState } from 'react'
import { View, Text, ScrollView, TouchableOpacity, ActivityIndicator, Alert } from 'react-native'
import { usePantryStore } from '../../stores/pantryStore'
import { useGroceryStore } from '../../stores/groceryStore'
import { useAuthStore } from '../../stores/authStore'
import { useSavedRecipeStore } from '../../stores/savedRecipeStore'
import { useProfileStore } from '../../stores/profileStore'
import { useCookedMealStore } from '../../stores/cookedMealStore'
import { generateRecipe } from '../../services/recipeService'
import { getHomeRecommendation } from '../../services/homeRecommendationEngine'
import { PantryItem, Recipe, SavedRecipe } from '../../types'
import { SectionHeader } from '../../components/SectionHeader'
import { ManagementCard } from '../../components/ManagementCard'
import { colors, spacing, radius, typography } from '../../theme'
import { useRouter } from 'expo-router'

function localDateStr(d: Date = new Date()): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function daysUntilExpiry(expiryDate: string): number {
  const today = new Date(localDateStr() + 'T00:00:00')
  const expiry = new Date(expiryDate + 'T00:00:00')
  return Math.round((expiry.getTime() - today.getTime()) / 86400000)
}

function expiryLabel(days: number): string {
  if (days < 0) return `expired ${Math.abs(days)} day${Math.abs(days) === 1 ? '' : 's'} ago`
  if (days === 0) return 'expires today'
  if (days === 1) return 'expires tomorrow'
  return `expires in ${days} days`
}

export default function HomeScreen() {
  const router = useRouter()
  const { items: pantryItems, fetchItems: fetchPantry } = usePantryStore()
  const { items: groceryItems, fetchItems: fetchGrocery } = useGroceryStore()
  const { email } = useAuthStore()
  const { recipes: savedRecipes, saveRecipe, fetchRecipes } = useSavedRecipeStore()
  const { profile, fetchProfile } = useProfileStore()
  const { todayCalories, todayProteinG, logCooked, fetchToday } = useCookedMealStore()
  const [recipe, setRecipe] = useState<Recipe | null>(null)
  const [isGenerating, setIsGenerating] = useState(false)
  const [isSaved, setIsSaved] = useState(false)

  const greeting = email ? email.split('@')[0] : 'there'

  useEffect(() => {
    fetchPantry()
    fetchGrocery()
    fetchProfile()
    fetchRecipes()
    fetchToday()
  }, [])

  useEffect(() => {
    if (recipe) {
      setIsSaved(savedRecipes.some(r => r.recipe.id === recipe.id))
    }
  }, [recipe, savedRecipes])

  const handleGenerateRecipe = async () => {
    if (pantryItems.length === 0) {
      Alert.alert('Pantry is empty', 'Add some items to your pantry first.')
      return
    }
    setIsGenerating(true)
    setRecipe(null)
    setIsSaved(false)
    try {
      const result = await generateRecipe(pantryItems, profile)
      setRecipe(result)
    } catch (err) {
      Alert.alert('Error', (err as Error).message)
    } finally {
      setIsGenerating(false)
    }
  }

  const handleSave = async () => {
    if (!recipe) return
    const { data: { user } } = await (await import('../../services/supabase')).supabase.auth.getUser()
    if (!user) return
    await saveRecipe(recipe, user.id, user.id, profile?.name ?? email ?? 'Me')
    setIsSaved(true)
  }

  const handleCooked = async () => {
    if (!recipe) return
    const { data: { user } } = await (await import('../../services/supabase')).supabase.auth.getUser()
    if (!user) return
    await logCooked(recipe, user.id, user.id, profile?.name ?? email ?? 'Me')
  }

  const dailyProteinGoal = profile?.nutrition_goals?.daily_protein_g ?? 0
  const dailyCalGoal = profile?.nutrition_goals?.daily_calories ?? 0

  // H3: Best Next Step
  const recommendation = getHomeRecommendation({
    pantryItems,
    savedRecipes,
    todayProteinG,
    dailyProteinGoal,
  })

  // H4: Attention Needed — items expiring within 3 days (or already expired)
  const expiringItems = pantryItems
    .filter(item => item.expiry_date !== null)
    .map(item => ({ ...item, daysLeft: daysUntilExpiry(item.expiry_date!) }))
    .filter(item => item.daysLeft <= 3)
    .sort((a, b) => a.daysLeft - b.daysLeft)

  // H5: Cook Faster — favorites first, then by saved_at descending, cap at 3
  const cookFasterRecipes = [...savedRecipes]
    .sort((a, b) => {
      if (a.is_favorite !== b.is_favorite) return a.is_favorite ? -1 : 1
      return b.saved_at.localeCompare(a.saved_at)
    })
    .slice(0, 3)

  const cookSubtitle = pantryItems.length === 0
    ? 'Build your pantry first, then generate recipes around what you already have.'
    : 'Use your pantry as the base. Your dietary preferences are applied automatically.'

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.background }}>
      <View style={{ padding: spacing.lg, gap: spacing.xl }}>

        {/* Greeting */}
        <Text style={[typography.title2, { color: colors.textPrimary }]}>
          What's cooking {greeting}?!
        </Text>

        {/* H3: Best Next Step */}
        {recommendation && (
          <RecommendationCard recommendation={recommendation} onPress={() => {
            if (recommendation.type === 'fill-pantry') router.push('/(tabs)/pantry')
            else router.push('/(tabs)/saved')
          }} />
        )}

        {/* H4: Attention Needed */}
        {expiringItems.length > 0 && (
          <AttentionNeededSection items={expiringItems} onPress={() => router.push('/(tabs)/pantry')} />
        )}

        {/* H2: Nutrition progress */}
        {dailyCalGoal > 0 && (
          <View style={{ gap: spacing.md }}>
            <SectionHeader title="Today's Nutrition" subtitle="" />
            <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, padding: spacing.lg, gap: spacing.md }}>
              <NutritionBar label="Calories" current={todayCalories} goal={dailyCalGoal} unit="" color={colors.warning} />
              <NutritionBar label="Protein" current={todayProteinG} goal={dailyProteinGoal} unit="g" color={colors.success} />
            </View>
          </View>
        )}

        {/* H5: Cook Faster */}
        {cookFasterRecipes.length > 0 && (
          <CookFasterSection
            recipes={cookFasterRecipes}
            hasMore={savedRecipes.length > 3}
            onPress={() => router.push('/(tabs)/saved')}
          />
        )}

        {/* Let's Cook */}
        <View style={{ gap: spacing.md }}>
          <SectionHeader title="Let's Cook" subtitle={cookSubtitle} />
          <TouchableOpacity
            onPress={handleGenerateRecipe}
            disabled={isGenerating}
            activeOpacity={0.8}
            style={{ padding: spacing.lg, borderRadius: 18, backgroundColor: colors.primary + '1F' }}
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
                  alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center',
                  gap: spacing.xs, paddingHorizontal: spacing.md, paddingVertical: spacing.xs,
                  backgroundColor: colors.primary + '1F', borderRadius: radius.chip,
                }}>
                  <Text style={[typography.caption, { color: colors.primary, fontWeight: '600' }]}>
                    ✨  {pantryItems.length} items in pantry
                  </Text>
                </View>
              </View>
            )}
          </TouchableOpacity>

          {recipe && (
            <RecipeCard
              recipe={recipe}
              isSaved={isSaved}
              onSave={handleSave}
              onCooked={handleCooked}
            />
          )}
        </View>

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

// ─── Sub-components ──────────────────────────────────────────────────────────

type HomeRecommendation = ReturnType<typeof getHomeRecommendation>

function RecommendationCard({ recommendation, onPress }: {
  recommendation: NonNullable<HomeRecommendation>
  onPress: () => void
}) {
  if (recommendation.type === 'fill-pantry') {
    return (
      <TouchableOpacity onPress={onPress} activeOpacity={0.8} style={{
        backgroundColor: colors.warning + '1F', padding: spacing.lg,
        borderRadius: radius.card, gap: spacing.xs,
      }}>
        <Text style={[typography.headline, { color: colors.textPrimary }]}>🥘  Build your pantry</Text>
        <Text style={[typography.subheadline, { color: colors.textSecondary }]}>
          Add your first ingredients to start generating recipes.
        </Text>
      </TouchableOpacity>
    )
  }

  if (recommendation.type === 'tonight-pick') {
    return (
      <TouchableOpacity onPress={onPress} activeOpacity={0.8} style={{
        backgroundColor: colors.success + '1F', padding: spacing.lg,
        borderRadius: radius.card, gap: spacing.xs,
      }}>
        <Text style={[typography.caption, { color: colors.success, fontWeight: '700', letterSpacing: 0.5 }]}>
          TONIGHT'S PICK  ·  +{recommendation.proteinGap}g protein gap
        </Text>
        <Text style={[typography.headline, { color: colors.textPrimary }]}>
          🏆  {recommendation.recipe.recipe.title}
        </Text>
        <Text style={[typography.subheadline, { color: colors.textSecondary }]}>
          {recommendation.recipe.recipe.protein}g protein · {recommendation.recipe.recipe.calories} cal
        </Text>
      </TouchableOpacity>
    )
  }

  // cook-favorite
  return (
    <TouchableOpacity onPress={onPress} activeOpacity={0.8} style={{
      backgroundColor: colors.primary + '1F', padding: spacing.lg,
      borderRadius: radius.card, gap: spacing.xs,
    }}>
      <Text style={[typography.caption, { color: colors.primary, fontWeight: '700', letterSpacing: 0.5 }]}>
        COOK TONIGHT
      </Text>
      <Text style={[typography.headline, { color: colors.textPrimary }]}>
        ⭐  {recommendation.recipe.recipe.title}
      </Text>
      <Text style={[typography.subheadline, { color: colors.textSecondary }]}>
        {recommendation.recipe.recipe.protein}g protein · {recommendation.recipe.recipe.calories} cal
      </Text>
    </TouchableOpacity>
  )
}

function AttentionNeededSection({ items, onPress }: {
  items: (PantryItem & { daysLeft: number })[]
  onPress: () => void
}) {
  return (
    <View style={{ gap: spacing.md }}>
      <SectionHeader title="Attention Needed" subtitle="" />
      <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, overflow: 'hidden' }}>
        {items.slice(0, 3).map((item, idx) => (
          <View key={item.id} style={{
            flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
            paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
            borderBottomWidth: idx < Math.min(items.length, 3) - 1 ? 1 : 0,
            borderBottomColor: colors.border,
          }}>
            <Text style={[typography.subheadline, { color: colors.textPrimary }]}>{item.name}</Text>
            <Text style={[typography.caption, {
              color: item.daysLeft < 0 ? colors.danger : item.daysLeft === 0 ? colors.warning : colors.textSecondary,
              fontWeight: '600',
            }]}>
              {expiryLabel(item.daysLeft)}
            </Text>
          </View>
        ))}
        <TouchableOpacity onPress={onPress} activeOpacity={0.8} style={{
          paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
          borderTopWidth: 1, borderTopColor: colors.border,
        }}>
          <Text style={[typography.subheadline, { color: colors.primary, fontWeight: '600' }]}>
            Review in Pantry →
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  )
}

function CookFasterSection({ recipes, hasMore, onPress }: {
  recipes: SavedRecipe[]
  hasMore: boolean
  onPress: () => void
}) {
  return (
    <View style={{ gap: spacing.md }}>
      <SectionHeader title="Cook Faster" subtitle="Jump into a meal you've already saved." />
      <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, overflow: 'hidden' }}>
        {recipes.map((saved, idx) => (
          <TouchableOpacity key={saved.id} onPress={onPress} activeOpacity={0.8} style={{
            flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
            paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
            borderBottomWidth: idx < recipes.length - 1 ? 1 : 0,
            borderBottomColor: colors.border,
          }}>
            <View style={{ flex: 1, gap: 2 }}>
              <Text style={[typography.subheadline, { color: colors.textPrimary }]}>
                {saved.is_favorite ? '⭐  ' : ''}{saved.recipe.title}
              </Text>
              <Text style={[typography.caption, { color: colors.textSecondary }]}>
                {saved.recipe.protein}g protein · {saved.recipe.calories} cal
              </Text>
            </View>
            <Text style={{ color: colors.textTertiary, fontSize: 18 }}>›</Text>
          </TouchableOpacity>
        ))}
        {hasMore && (
          <TouchableOpacity onPress={onPress} activeOpacity={0.8} style={{
            paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
            borderTopWidth: 1, borderTopColor: colors.border,
          }}>
            <Text style={[typography.subheadline, { color: colors.primary, fontWeight: '600' }]}>
              See all saved recipes →
            </Text>
          </TouchableOpacity>
        )}
      </View>
    </View>
  )
}

function NutritionBar({ label, current, goal, unit, color }: {
  label: string; current: number; goal: number; unit: string; color: string
}) {
  const pct = goal > 0 ? Math.min(current / goal, 1) : 0
  return (
    <View style={{ gap: spacing.xs }}>
      <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
        <Text style={[typography.caption, { color: colors.textSecondary }]}>{label}</Text>
        <Text style={[typography.caption, { color: colors.textSecondary }]}>
          {current}{unit} / {goal}{unit}
        </Text>
      </View>
      <View style={{ height: 6, backgroundColor: colors.border, borderRadius: 3 }}>
        <View style={{ height: 6, width: `${pct * 100}%` as any, backgroundColor: color, borderRadius: 3 }} />
      </View>
    </View>
  )
}

function RecipeCard({ recipe, isSaved, onSave, onCooked }: {
  recipe: Recipe; isSaved: boolean; onSave: () => void; onCooked: () => void
}) {
  return (
    <View style={{ backgroundColor: colors.surface, padding: spacing.lg, borderRadius: radius.card, gap: spacing.md }}>
      <Text style={[typography.headline, { color: colors.textPrimary }]}>{recipe.title}</Text>

      <View style={{ gap: spacing.xs }}>
        <Text style={[typography.caption, { color: colors.textSecondary, fontWeight: '600' }]}>INGREDIENTS</Text>
        {recipe.ingredients.map((ing, idx) => (
          <Text key={idx} style={[typography.subheadline, { color: colors.textSecondary }]}>
            • {ing.name} ({ing.quantity})
          </Text>
        ))}
      </View>

      <View style={{ gap: spacing.xs }}>
        <Text style={[typography.caption, { color: colors.textSecondary, fontWeight: '600' }]}>INSTRUCTIONS</Text>
        {recipe.instructions.map((inst, idx) => (
          <Text key={idx} style={[typography.subheadline, { color: colors.textSecondary }]}>
            {idx + 1}. {inst}
          </Text>
        ))}
      </View>

      <View style={{ flexDirection: 'row', justifyContent: 'space-around', paddingTop: spacing.md, borderTopWidth: 1, borderTopColor: colors.border }}>
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

      <View style={{ flexDirection: 'row', gap: spacing.sm }}>
        <TouchableOpacity
          onPress={onSave}
          disabled={isSaved}
          style={{
            flex: 1, padding: spacing.md, borderRadius: radius.button, alignItems: 'center',
            backgroundColor: isSaved ? colors.surface : colors.primary,
            borderWidth: isSaved ? 1 : 0, borderColor: colors.border,
          }}
        >
          <Text style={[typography.headline, { color: isSaved ? colors.textTertiary : colors.background }]}>
            {isSaved ? '✓ Saved' : 'Save Recipe'}
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          onPress={onCooked}
          style={{
            flex: 1, padding: spacing.md, borderRadius: radius.button, alignItems: 'center',
            backgroundColor: colors.success + '1F',
          }}
        >
          <Text style={[typography.headline, { color: colors.success }]}>I Cooked This</Text>
        </TouchableOpacity>
      </View>
    </View>
  )
}
