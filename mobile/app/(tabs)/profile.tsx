import { View, Text, TouchableOpacity, ScrollView } from 'react-native'
import { useAuthStore } from '../../stores/authStore'
import { colors, spacing, radius, typography } from '../../theme'

export default function ProfileScreen() {
  const { email, signOut, isLoading } = useAuthStore()

  return (
    <ScrollView style={{ flex: 1, backgroundColor: colors.background }}>
      <View style={{ padding: spacing.lg, gap: spacing.xl }}>

        {/* Account */}
        <View style={{ gap: spacing.md }}>
          <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600', letterSpacing: 0.5 }]}>
            ACCOUNT
          </Text>
          <View style={{
            backgroundColor: colors.surface,
            borderRadius: radius.card,
            paddingHorizontal: spacing.lg,
            paddingVertical: spacing.md,
          }}>
            <Text style={[typography.caption, { color: colors.textTertiary }]}>Signed in as</Text>
            <Text style={[typography.headline, { color: colors.textPrimary, marginTop: spacing.xs }]}>
              {email ?? '—'}
            </Text>
          </View>
        </View>

        {/* Sign out */}
        <TouchableOpacity
          onPress={signOut}
          disabled={isLoading}
          activeOpacity={0.8}
          style={{
            backgroundColor: colors.danger + '1F',
            padding: spacing.lg,
            borderRadius: radius.button,
            alignItems: 'center',
          }}
        >
          <Text style={[typography.headline, { color: colors.danger }]}>
            {isLoading ? 'Signing out…' : 'Sign Out'}
          </Text>
        </TouchableOpacity>

      </View>
    </ScrollView>
  )
}
