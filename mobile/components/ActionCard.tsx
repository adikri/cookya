import { TouchableOpacity, View, Text } from 'react-native'
import { colors, spacing, radius, typography } from '../theme'

interface Props {
  title: string
  subtitle: string
  icon: string
  tintColor?: string
  onPress?: () => void
}

export function ActionCard({ title, subtitle, icon, onPress }: Props) {
  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.7}
      style={{
        flexDirection: 'row',
        alignItems: 'flex-start',
        gap: spacing.md,
        padding: spacing.lg,
        backgroundColor: colors.surface,
        borderRadius: radius.card,
      }}
    >
      <Text style={{ fontSize: 20, width: 28, textAlign: 'center', marginTop: 2 }}>{icon}</Text>
      <View style={{ flex: 1, gap: spacing.xs }}>
        <Text style={[typography.headline, { color: colors.textPrimary }]}>{title}</Text>
        <Text style={[typography.subheadline, { color: colors.textSecondary }]}>{subtitle}</Text>
      </View>
      <Text style={{ color: colors.textTertiary, fontSize: 20, alignSelf: 'center' }}>›</Text>
    </TouchableOpacity>
  )
}
