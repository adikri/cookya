import { ScrollView, TouchableOpacity, Text, View } from 'react-native'
import { colors, spacing, radius, typography } from '../theme'

const CATEGORIES: { value: string; label: string; icon: string }[] = [
  { value: 'vegetables', label: 'Vegetables', icon: '🥦' },
  { value: 'protein',    label: 'Protein',    icon: '🥩' },
  { value: 'grains',     label: 'Grains',     icon: '🌾' },
  { value: 'dairy',      label: 'Dairy',      icon: '🥛' },
  { value: 'fruit',      label: 'Fruit',      icon: '🍎' },
  { value: 'bakery',     label: 'Bakery',     icon: '🍞' },
  { value: 'condiments', label: 'Condiments', icon: '🧂' },
  { value: 'beverages',  label: 'Beverages',  icon: '🥤' },
  { value: 'other',      label: 'Other',      icon: '📦' },
]

interface Props {
  value: string
  onChange: (value: string) => void
}

export function CategoryPicker({ value, onChange }: Props) {
  return (
    <View style={{ gap: spacing.xs }}>
      <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600' }]}>
        CATEGORY
      </Text>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginHorizontal: -spacing.xs }}>
        <View style={{ flexDirection: 'row', gap: spacing.xs, paddingHorizontal: spacing.xs }}>
          {CATEGORIES.map((cat) => {
            const selected = value === cat.value
            return (
              <TouchableOpacity
                key={cat.value}
                onPress={() => onChange(cat.value)}
                style={{
                  flexDirection: 'row',
                  alignItems: 'center',
                  gap: spacing.xs,
                  paddingHorizontal: spacing.md,
                  paddingVertical: spacing.sm,
                  borderRadius: radius.chip,
                  backgroundColor: selected ? colors.primary : colors.background,
                  borderWidth: 1,
                  borderColor: selected ? colors.primary : colors.border,
                }}
              >
                <Text style={{ fontSize: 14 }}>{cat.icon}</Text>
                <Text style={[
                  typography.caption,
                  { color: selected ? colors.background : colors.textSecondary, fontWeight: '600' },
                ]}>
                  {cat.label}
                </Text>
              </TouchableOpacity>
            )
          })}
        </View>
      </ScrollView>
    </View>
  )
}
