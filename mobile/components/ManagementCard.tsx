import { TouchableOpacity, View, Text } from 'react-native'
import { colors, spacing, radius, typography } from '../theme'

interface Props {
  title: string
  subtitle: string
  detail: string
  icon: string
  onPress?: () => void
}

export function ManagementCard({ title, subtitle, detail, icon, onPress }: Props) {
  return (
    <TouchableOpacity
      onPress={onPress}
      activeOpacity={0.7}
      style={{
        flex: 1,
        padding: spacing.lg,
        backgroundColor: colors.surface,
        borderRadius: radius.card,
        gap: spacing.sm,
      }}
    >
      <Text style={{ fontSize: 24 }}>{icon}</Text>
      <Text style={[typography.headline, { color: colors.textPrimary }]}>{title}</Text>
      <Text style={[typography.subheadline, { color: colors.textPrimary }]}>{subtitle}</Text>
      <Text style={[typography.caption, { color: colors.textSecondary }]}>{detail}</Text>
      <View style={{ alignItems: 'flex-end' }}>
        <Text style={{ color: colors.textTertiary, fontSize: 16 }}>›</Text>
      </View>
    </TouchableOpacity>
  )
}
