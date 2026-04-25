import { useState, useMemo } from 'react'
import { View, Text, TextInput, TouchableOpacity, FlatList, Modal } from 'react-native'
import { colors, spacing, radius, typography } from '../theme'
import catalog from '../assets/catalog.json'

interface CatalogItem { name: string; category: string; quantity: string }
const CATALOG: CatalogItem[] = catalog as CatalogItem[]

interface Props {
  onSelect: (name: string, quantity: string, category: string) => void
  onDismiss: () => void
}

export function ItemPicker({ onSelect, onDismiss }: Props) {
  const [query, setQuery] = useState('')

  const results = useMemo(() => {
    if (!query.trim()) return CATALOG.slice(0, 30)
    const q = query.toLowerCase().trim()
    return CATALOG.filter(item => item.name.toLowerCase().includes(q)).slice(0, 50)
  }, [query])

  return (
    <Modal animationType="slide" presentationStyle="pageSheet" onRequestClose={onDismiss}>
      <View style={{ flex: 1, backgroundColor: colors.background }}>

        {/* Header */}
        <View style={{
          flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
          paddingHorizontal: spacing.lg, paddingTop: spacing.xl, paddingBottom: spacing.md,
          borderBottomWidth: 1, borderBottomColor: colors.border,
        }}>
          <Text style={[typography.headline, { color: colors.textPrimary }]}>Choose an item</Text>
          <TouchableOpacity onPress={onDismiss}>
            <Text style={[typography.subheadline, { color: colors.primary }]}>Cancel</Text>
          </TouchableOpacity>
        </View>

        {/* Search */}
        <View style={{ padding: spacing.lg, paddingBottom: spacing.sm }}>
          <TextInput
            placeholder="Search items…"
            value={query}
            onChangeText={setQuery}
            autoFocus
            placeholderTextColor={colors.textTertiary}
            style={{
              borderWidth: 1, borderColor: colors.border,
              padding: spacing.md, borderRadius: radius.button,
              ...typography.body, color: colors.textPrimary,
              backgroundColor: colors.surface,
            }}
          />
        </View>

        {/* Results */}
        <FlatList
          data={results}
          keyExtractor={(item) => item.name}
          keyboardShouldPersistTaps="handled"
          renderItem={({ item }) => (
            <TouchableOpacity
              onPress={() => { onSelect(item.name, item.quantity, item.category); onDismiss() }}
              style={{
                flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
                paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
                borderBottomWidth: 1, borderBottomColor: colors.border,
              }}
            >
              <Text style={[typography.body, { color: colors.textPrimary }]}>{item.name}</Text>
              <Text style={[typography.caption, { color: colors.textTertiary }]}>{item.quantity}</Text>
            </TouchableOpacity>
          )}
          ListFooterComponent={
            query.trim() ? (
              <TouchableOpacity
                onPress={() => { onSelect(query.trim(), '', 'other'); onDismiss() }}
                style={{
                  paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
                  borderBottomWidth: 1, borderBottomColor: colors.border,
                }}
              >
                <Text style={[typography.body, { color: colors.primary }]}>
                  + Add "{query.trim()}" as custom item
                </Text>
              </TouchableOpacity>
            ) : null
          }
        />
      </View>
    </Modal>
  )
}
