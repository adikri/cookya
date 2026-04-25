import { useEffect, useState } from 'react'
import { View, Text, TouchableOpacity, ScrollView, TextInput, Switch } from 'react-native'
import { useAuthStore } from '../../stores/authStore'
import { useProfileStore } from '../../stores/profileStore'
import { colors, spacing, radius, typography } from '../../theme'

export default function ProfileScreen() {
  const { email, signOut, isLoading: authLoading } = useAuthStore()
  const { profile, fetchProfile, upsertProfile, isLoading: profileLoading } = useProfileStore()
  const [name, setName] = useState('')
  const [isVegetarian, setIsVegetarian] = useState(false)
  const [avoidText, setAvoidText] = useState('')
  const [editing, setEditing] = useState(false)
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    fetchProfile()
  }, [])

  useEffect(() => {
    if (profile) {
      setName(profile.name)
      setIsVegetarian(profile.is_vegetarian)
      setAvoidText(profile.avoid_food_items.join(', '))
    }
  }, [profile])

  const handleSave = async () => {
    const avoid = avoidText.split(',').map(s => s.trim()).filter(Boolean)
    await upsertProfile({ name: name.trim() || (email ?? 'Me'), is_vegetarian: isVegetarian, avoid_food_items: avoid })
    setEditing(false)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

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

        {/* Dietary preferences */}
        <View style={{ gap: spacing.md }}>
          <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
            <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600', letterSpacing: 0.5 }]}>
              DIETARY PREFERENCES
            </Text>
            {!editing && (
              <TouchableOpacity onPress={() => setEditing(true)}>
                <Text style={[typography.caption, { color: colors.primary, fontWeight: '600' }]}>Edit</Text>
              </TouchableOpacity>
            )}
          </View>

          <View style={{ backgroundColor: colors.surface, borderRadius: radius.card, padding: spacing.lg, gap: spacing.lg }}>
            {/* Name */}
            <View style={{ gap: spacing.xs }}>
              <Text style={[typography.caption, { color: colors.textTertiary }]}>Name</Text>
              {editing ? (
                <TextInput
                  value={name}
                  onChangeText={setName}
                  placeholder="Your name"
                  placeholderTextColor={colors.textTertiary}
                  style={[typography.body, {
                    color: colors.textPrimary, borderBottomWidth: 1,
                    borderBottomColor: colors.border, paddingVertical: spacing.xs,
                  }]}
                />
              ) : (
                <Text style={[typography.body, { color: colors.textPrimary }]}>{profile?.name ?? '—'}</Text>
              )}
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
                onPress={() => { setEditing(false); if (profile) { setName(profile.name); setIsVegetarian(profile.is_vegetarian); setAvoidText(profile.avoid_food_items.join(', ')) } }}
                style={{ flex: 1, backgroundColor: colors.border, padding: spacing.md, borderRadius: radius.button, alignItems: 'center' }}
              >
                <Text style={[typography.headline, { color: colors.textSecondary }]}>Cancel</Text>
              </TouchableOpacity>
            </View>
          )}
        </View>

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
