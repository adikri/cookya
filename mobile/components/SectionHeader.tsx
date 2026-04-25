import { View, Text } from 'react-native'
import { colors, spacing, typography } from '../theme'

interface Props {
  title: string
  subtitle?: string
}

export function SectionHeader({ title, subtitle }: Props) {
  return (
    <View style={{ gap: spacing.xs }}>
      <Text style={[typography.headline, { color: colors.textPrimary }]}>{title}</Text>
      {subtitle ? (
        <Text style={[typography.subheadline, { color: colors.textSecondary }]}>{subtitle}</Text>
      ) : null}
    </View>
  )
}
