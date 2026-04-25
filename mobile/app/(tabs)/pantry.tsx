import { useEffect, useState } from 'react'
import { View, FlatList, TouchableOpacity, Text, TextInput, Alert } from 'react-native'
import { usePantryStore } from '../../stores/pantryStore'
import { CategoryPicker } from '../../components/CategoryPicker'
import { ItemPicker } from '../../components/ItemPicker'
import { colors, spacing, radius, typography } from '../../theme'

const EXPIRY_OPTIONS = [
  { label: 'Today', days: 0 },
  { label: '3 days', days: 3 },
  { label: '1 week', days: 7 },
  { label: '2 weeks', days: 14 },
  { label: '1 month', days: 30 },
  { label: 'No expiry', days: null },
]

function expiryDate(days: number | null): string | null {
  if (days === null) return null
  const d = new Date()
  d.setDate(d.getDate() + days)
  return d.toISOString()
}

function daysUntilExpiry(dateStr: string | null): number | null {
  if (!dateStr) return null
  const diff = new Date(dateStr).getTime() - Date.now()
  return Math.ceil(diff / (1000 * 60 * 60 * 24))
}

function expiryLabel(dateStr: string | null): string {
  if (!dateStr) return ''
  const days = daysUntilExpiry(dateStr)
  if (days === null) return ''
  if (days < 0) return '⚠️ Expired'
  if (days === 0) return '⚠️ Expires today'
  if (days === 1) return 'Expires tomorrow'
  return `Expires in ${days}d`
}

export default function PantryScreen() {
  const { items, fetchItems, addItem, deleteItem, isLoading, error } = usePantryStore()
  const [showAddForm, setShowAddForm] = useState(false)
  const [showPicker, setShowPicker] = useState(false)
  const [name, setName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [category, setCategory] = useState('vegetables')
  const [selectedExpiry, setSelectedExpiry] = useState<number | null>(null)

  useEffect(() => { fetchItems() }, [])

  const resetForm = () => {
    setName(''); setQuantity(''); setCategory('vegetables'); setSelectedExpiry(null)
  }

  const handleAddItem = async () => {
    if (!name || !quantity) {
      Alert.alert('Error', 'Please fill in all fields')
      return
    }
    await addItem(name, quantity, category, expiryDate(selectedExpiry))
    resetForm()
    setShowAddForm(false)
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => {
          const expLabel = expiryLabel(item.expiry_date)
          const isExpired = expLabel.includes('Expired')
          return (
            <View style={{
              flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
              paddingHorizontal: spacing.lg, paddingVertical: spacing.md,
              borderBottomWidth: 1, borderBottomColor: colors.border,
              opacity: isExpired ? 0.6 : 1,
            }}>
              <View style={{ flex: 1 }}>
                <Text style={[typography.headline, { color: colors.textPrimary }]}>{item.name}</Text>
                <Text style={[typography.subheadline, { color: colors.textSecondary, marginTop: spacing.xs }]}>
                  {item.quantity_text} · {item.category}
                </Text>
                {expLabel ? (
                  <Text style={[typography.caption, {
                    color: isExpired || expLabel.includes('today') ? colors.danger : colors.textTertiary,
                    marginTop: spacing.xs,
                  }]}>
                    {expLabel}
                  </Text>
                ) : null}
              </View>
              <TouchableOpacity
                onPress={() => deleteItem(item.id)}
                style={{ padding: spacing.sm, marginLeft: spacing.md }}
              >
                <Text style={[typography.subheadline, { color: colors.danger, fontWeight: '600' }]}>Delete</Text>
              </TouchableOpacity>
            </View>
          )
        }}
        ListEmptyComponent={
          !isLoading ? (
            <View style={{ padding: spacing.xl, alignItems: 'center' }}>
              <Text style={[typography.subheadline, { color: colors.textTertiary }]}>No items in pantry</Text>
            </View>
          ) : null
        }
      />

      {error ? (
        <View style={{ paddingHorizontal: spacing.lg, paddingVertical: spacing.sm, backgroundColor: colors.danger + '1F' }}>
          <Text style={[typography.caption, { color: colors.danger }]}>{error}</Text>
        </View>
      ) : null}

      {showAddForm && (
        <View style={{
          padding: spacing.lg, backgroundColor: colors.surface,
          borderTopWidth: 1, borderTopColor: colors.border, gap: spacing.md,
        }}>
          {/* Catalog picker button */}
          <TouchableOpacity
            onPress={() => setShowPicker(true)}
            style={{
              padding: spacing.md, borderRadius: radius.button, alignItems: 'center',
              borderWidth: 1, borderColor: colors.primary, borderStyle: 'dashed',
            }}
          >
            <Text style={[typography.subheadline, { color: colors.primary }]}>
              🔍  Search catalog
            </Text>
          </TouchableOpacity>

          <TextInput
            placeholder="Item name"
            value={name}
            onChangeText={setName}
            placeholderTextColor={colors.textTertiary}
            style={{
              borderWidth: 1, borderColor: colors.border, padding: spacing.md,
              borderRadius: radius.button, ...typography.body,
              color: colors.textPrimary, backgroundColor: colors.background,
            }}
          />
          <TextInput
            placeholder="Quantity (e.g., 2 cups)"
            value={quantity}
            onChangeText={setQuantity}
            placeholderTextColor={colors.textTertiary}
            style={{
              borderWidth: 1, borderColor: colors.border, padding: spacing.md,
              borderRadius: radius.button, ...typography.body,
              color: colors.textPrimary, backgroundColor: colors.background,
            }}
          />

          <CategoryPicker value={category} onChange={setCategory} />

          {/* Expiry picker */}
          <View style={{ gap: spacing.xs }}>
            <Text style={[typography.caption, { color: colors.textTertiary, fontWeight: '600' }]}>EXPIRES IN</Text>
            <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs }}>
              {EXPIRY_OPTIONS.map((opt) => {
                const selected = selectedExpiry === opt.days
                return (
                  <TouchableOpacity
                    key={opt.label}
                    onPress={() => setSelectedExpiry(opt.days)}
                    style={{
                      paddingHorizontal: spacing.md, paddingVertical: spacing.sm,
                      borderRadius: radius.chip, borderWidth: 1,
                      backgroundColor: selected ? colors.primary : colors.background,
                      borderColor: selected ? colors.primary : colors.border,
                    }}
                  >
                    <Text style={[typography.caption, {
                      color: selected ? colors.background : colors.textSecondary, fontWeight: '600',
                    }]}>
                      {opt.label}
                    </Text>
                  </TouchableOpacity>
                )
              })}
            </View>
          </View>

          <View style={{ flexDirection: 'row', gap: spacing.sm }}>
            <TouchableOpacity
              onPress={handleAddItem}
              style={{ flex: 1, backgroundColor: colors.primary, padding: spacing.md, borderRadius: radius.button, alignItems: 'center' }}
            >
              <Text style={[typography.headline, { color: colors.background }]}>Add Item</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => { setShowAddForm(false); resetForm() }}
              style={{ flex: 1, backgroundColor: colors.border, padding: spacing.md, borderRadius: radius.button, alignItems: 'center' }}
            >
              <Text style={[typography.headline, { color: colors.textSecondary }]}>Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      )}

      {!showAddForm && (
        <TouchableOpacity
          onPress={() => setShowAddForm(true)}
          style={{ backgroundColor: colors.primary, padding: spacing.lg, margin: spacing.lg, borderRadius: radius.button, alignItems: 'center' }}
        >
          <Text style={[typography.headline, { color: colors.background }]}>+ Add Item</Text>
        </TouchableOpacity>
      )}

      {showPicker && (
        <ItemPicker
          onSelect={(n, q, c) => { setName(n); setQuantity(q); setCategory(c) }}
          onDismiss={() => setShowPicker(false)}
        />
      )}
    </View>
  )
}
