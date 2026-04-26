import { useEffect, useState } from 'react'
import { View, Text, TouchableOpacity, ScrollView, TextInput, Switch } from 'react-native'
import { useAuthStore } from '../../stores/authStore'
import { useProfileStore } from '../../stores/profileStore'
import { NutritionGoals } from '../../types'
import { colors, spacing, radius, typography } from '../../theme'

function calcBmi(weightKg: number, heightCm: number): number {
  const hm = heightCm / 100
  return Math.round((weightKg / (hm * hm)) * 10) / 10
}

// Mifflin-St Jeor (gender-neutral average offset), moderately active
function calcNutritionGoals(age: number, weightKg: number, heightCm: number): NutritionGoals {
  const bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 78
  return {
    daily_calories: Math.round(bmr * 1.55),
    daily_protein_g: Math.round(weightKg * 1.6),
  }
}

export default function ProfileScreen() {
  const { email, signOut, isLoading: authLoading } = useAuthStore()
  const { profile, fetchProfile, upsertProfile, isLoading: profileLoading } = useProfileStore()

  const [name, setName] = useState('')
  const [age, setAge] = useState('')
  const [heightCm, setHeightCm] = useState('')
  const [weightKg, setWeightKg] = useState('')
  const [isVegetarian, setIsVegetarian] = useState(false)
  const [avoidText, setAvoidText] = useState('')
  const [editing, setEditing] = useState(false)
  const [saved, setSaved] = useState(false)

  useEffect(() => { fetchProfile() }, [])

  useEffect(() => {
    if (profile) {
      setName(profile.name ?? '')
      setAge(profile.age != null ? String(profile.age) : '')
      setHeightCm(profile.height_cm != null ? String(profile.height_cm) : '')
      setWeightKg(profile.weight_kg != null ? String(profile.weight_kg) : '')
      setIsVegetarian(profile.is_vegetarian)
      setAvoidText(profile.avoid_food_items.join(', '))
    }
  }, [profile])

  const handleSave = async () => {
    const ageNum = age ? parseInt(age, 10) : null
    const heightNum = heightCm ? parseFloat(heightCm) : null
    const weightNum = weightKg ? parseFloat(weightKg) : null

    let nutrition_goals: NutritionGoals | null = profile?.nutrition_goals ?? null
    if (ageNum && heightNum && weightNum) {
      nutrition_goals = calcNutritionGoals(ageNum, weightNum, heightNum)
    }

    await upsertProfile({
      name: name.trim() || (email ?? 'Me'),
      age: ageNum,
      height_cm: heightNum,
      weight_kg: weightNum,
      is_vegetarian: isVegetarian,
      avoid_food_items: avoidText.split(',').map(s => s.trim()).filter(Boolean),
      nutrition_goals,
    })
    setEditing(false)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  const handleCancel = () => {
    setEditing(false)
    if (profile) {
      setName(profile.name ?? '')
      setAge(profile.age != null ? String(profile.age) : '')
      setHeightCm(profile.height_cm != null ? String(profile.height_cm) : '')
      setWeightKg(profile.weight_kg != null ? String(profile.weight_kg) : '')
      setIsVegetarian(profile.is_vegetarian)
      setAvoidText(profile.avoid_food_items.join(', '))
    }
  }

  const bmi = (() => {
    const w = weightKg ? parseFloat(weightKg) : null
    const h = heightCm ? parseFloat(heightCm) : null
    return w && h && h > 0 ? calcBmi(w, h) : null
  })()

  const bmiLabel = bmi === null ? null
    : bmi < 18.5 ? 'Underweight'
    : bmi < 25 ? 'Normal'
    : bmi < 30 ? 'Overweight'
    : 'Obese'

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.background }}>
      <View style={{ padding: spacing.lg, gap: spacing.xl }}>

        {/* Account */}
        <View style={{ gap: spacing.md }}>
          <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600', letterSpacing: 0.5 }]}>
            ACCOUNT
          </Text>
          <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, paddingHorizontal: spacing.lg, paddingVertical: spacing.md }}>
            <Text style={[typography.caption, { color: colors.textTertiary }]}>Signed in as</Text>
            <Text style={[typography.headline, { color: colors.textPrimary, marginTop: spacing.xs }]}>{email ?? '—'}</Text>
          </View>
        </View>

        {/* Personal details */}
        <View style={{ gap: spacing.md }}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
            <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600', letterSpacing: 0.5 }]}>
              PERSONAL DETAILS
            </Text>
            {!editing && (
              <TouchableOpacity onPress={() => setEditing(true)}>
                <Text style={[typography.caption, { color: colors.primary, fontWeight: '600' }]}>Edit</Text>
              </TouchableOpacity>
            )}
          </View>

          <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, padding: spacing.lg, gap: spacing.lg }}>

            <ProfileField label="Name" value={name} editing={editing} onChangeText={setName}
              placeholder="Your name" />

            <View style={{ flexDirection: 'row', gap: spacing.lg }}>
              <View style={{ flex: 1 }}>
                <ProfileField label="Age" value={age} editing={editing} onChangeText={setAge}
                  placeholder="—" keyboardType="numeric" />
              </View>
              <View style={{ flex: 1 }}>
                <ProfileField label="Height (cm)" value={heightCm} editing={editing} onChangeText={setHeightCm}
                  placeholder="—" keyboardType="decimal-pad" />
              </View>
            </View>

            <View style={{ flexDirection: 'row', gap: spacing.lg }}>
              <View style={{ flex: 1 }}>
                <ProfileField label="Weight (kg)" value={weightKg} editing={editing} onChangeText={setWeightKg}
                  placeholder="—" keyboardType="decimal-pad" />
              </View>
              <View style={{ flex: 1, gap: spacing.xs }}>
                <Text style={[typography.caption, { color: colors.textTertiary }]}>BMI</Text>
                <Text style={[typography.body, { color: bmi ? colors.textPrimary : colors.textTertiary }]}>
                  {bmi ?? '—'}{bmiLabel ? `  ${bmiLabel}` : ''}
                </Text>
              </View>
            </View>

            {/* Vegetarian */}
            <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <View>
                <Text style={[typography.body, { color: colors.textPrimary }]}>Vegetarian</Text>
                <Text style={[typography.caption, { color: colors.textTertiary }]}>No meat, fish, or seafood</Text>
              </View>
              <Switch
                value={isVegetarian}
                onValueChange={editing ? setIsVegetarian : undefined}
                trackColor={{ true: colors.primary, false: colors.border }}
                disabled={!editing}
              />
            </View>

            {/* Avoid items */}
            <View style={{ gap: spacing.xs }}>
              <Text style={[typography.caption, { color: colors.textTertiary }]}>Foods to avoid (comma-separated)</Text>
              {editing ? (
                <TextInput
                  value={avoidText}
                  onChangeText={setAvoidText}
                  placeholder="e.g. nuts, shellfish, dairy"
                  placeholderTextColor={colors.textTertiary}
                  style={[typography.body, {
                    color: colors.textPrimary, borderBottomWidth: 1,
                    borderBottomColor: colors.border, paddingVertical: spacing.xs,
                  }]}
                />
              ) : (
                <Text style={[typography.body, { color: profile?.avoid_food_items.length ? colors.textPrimary : colors.textTertiary }]}>
                  {profile?.avoid_food_items.length ? profile.avoid_food_items.join(', ') : 'None'}
                </Text>
              )}
            </View>
          </View>

          {editing && (
            <View style={{ flexDirection: 'row', gap: spacing.sm }}>
              <TouchableOpacity
                onPress={handleSave}
                disabled={profileLoading}
                style={{ flex: 1, backgroundColor: colors.primary, padding: spacing.md, borderRadius: radius.button, alignItems: 'center' }}
              >
                <Text style={[typography.headline, { color: colors.background }]}>
                  {profileLoading ? 'Saving…' : saved ? '✓ Saved' : 'Save'}
                </Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={handleCancel}
                style={{ flex: 1, backgroundColor: colors.border, padding: spacing.md, borderRadius: radius.button, alignItems: 'center' }}
              >
                <Text style={[typography.headline, { color: colors.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>

        {/* Nutrition goals (read-only, auto-calculated) */}
        {profile?.nutrition_goals && (
          <View style={{ gap: spacing.md }}>
            <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600', letterSpacing: 0.5 }]}>
              DAILY NUTRITION GOALS
            </Text>
            <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, padding: spacing.lg, flexDirection: 'row', gap: spacing.lg }}>
              <View style={{ flex: 1, alignItems: 'center', gap: spacing.xs }}>
                <Text style={[typography.caption, { color: colors.textTertiary }]}>Calories</Text>
                <Text style={[typography.headline, { color: colors.textPrimary }]}>{profile.nutrition_goals.daily_calories}</Text>
              </View>
              <View style={{ width: 1, backgroundColor: colors.border }} />
              <View style={{ flex: 1, alignItems: 'center', gap: spacing.xs }}>
                <Text style={[typography.caption, { color: colors.textTertiary }]}>Protein</Text>
                <Text style={[typography.headline, { color: colors.textPrimary }]}>{profile.nutrition_goals.daily_protein_g}g</Text>
              </View>
            </View>
            <Text style={[typography.caption, { color: colors.textTertiary }]}>
              Auto-calculated from your biometrics. Update age, height, or weight to recalculate.
            </Text>
          </View>
        )}

        {/* Sign out */}
        <TouchableOpacity
          onPress={signOut}
          disabled={authLoading}
          activeOpacity={0.8}
          style={{ backgroundColor: colors.danger + '1F', padding: spacing.lg, borderRadius: radius.button, alignItems: 'center' }}
        >
          <Text style={[typography.headline, { color: colors.danger }]}>
            {authLoading ? 'Signing out…' : 'Sign Out'}
          </Text>
        </TouchableOpacity>

      </View>
    </ScrollView>
  )
}

function ProfileField({ label, value, editing, onChangeText, placeholder, keyboardType }: {
  label: string
  value: string
  editing: boolean
  onChangeText: (v: string) => void
  placeholder?: string
  keyboardType?: 'default' | 'numeric' | 'decimal-pad'
}) {
  return (
    <View style={{ gap: spacing.xs }}>
      <Text style={[typography.caption, { color: colors.textTertiary }]}>{label}</Text>
      {editing ? (
        <TextInput
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.textTertiary}
          keyboardType={keyboardType ?? 'default'}
          style={[typography.body, {
            color: colors.textPrimary, borderBottomWidth: 1,
            borderBottomColor: colors.border, paddingVertical: spacing.xs,
          }]}
        />
      ) : (
        <Text style={[typography.body, { color: value ? colors.textPrimary : colors.textTertiary }]}>
          {value || '—'}
        </Text>
      )}
    </View>
  )
}
