import { useEffect, useState } from 'react'
import { View, FlatList, TouchableOpacity, Text, TextInput, Alert } from 'react-native'
import { useGroceryStore } from '../../stores/groceryStore'
import { CategoryPicker } from '../../components/CategoryPicker'
import { colors, spacing, radius, typography } from '../../theme'

export default function GroceryScreen() {
  const { items, fetchItems, addItem, markPurchased, deleteItem, isLoading, error } = useGroceryStore()
  const [showAddForm, setShowAddForm] = useState(false)
  const [name, setName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [category, setCategory] = useState('vegetables')
  const [note, setNote] = useState('')

  useEffect(() => {
    fetchItems()
  }, [])

  const handleAddItem = async () => {
    if (!name || !quantity) {
      Alert.alert('Error', 'Please fill in all fields')
      return
    }
    await addItem(name, quantity, category, note)
    setName('')
    setQuantity('')
    setCategory('vegetables')
    setNote('')
    setShowAddForm(false)
  }

  const handlePurchased = (id: string, item: any) => {
    markPurchased(id, item)
  }

  const handleDelete = (id: string) => {
    deleteItem(id)
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View style={{
            flexDirection: 'row',
            justifyContent: 'space-between',
            alignItems: 'center',
            paddingHorizontal: spacing.lg,
            paddingVertical: spacing.md,
            borderBottomWidth: 1,
            borderBottomColor: colors.border,
          }}>
            <View style={{ flex: 1 }}>
              <Text style={[typography.headline, { color: colors.textPrimary }]}>
                {item.name}
              </Text>
              <Text style={[typography.subheadline, { color: colors.textSecondary, marginTop: spacing.xs }]}>
                {item.quantity_text} · {item.category}
              </Text>
              {item.note && (
                <Text style={[typography.caption, { color: colors.textTertiary, marginTop: spacing.xs }]}>
                  {item.note}
                </Text>
              )}
            </View>
            <View style={{ flexDirection: 'row', gap: spacing.xs, marginLeft: spacing.md }}>
              <TouchableOpacity
                onPress={() => handlePurchased(item.id, item)}
                style={{
                  padding: spacing.sm,
                  backgroundColor: colors.success + '1F',
                  borderRadius: radius.button,
                }}
              >
                <Text style={[typography.headline, { color: colors.success }]}>✓</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => handleDelete(item.id)}
                style={{
                  padding: spacing.sm,
                  backgroundColor: colors.danger + '1F',
                  borderRadius: radius.button,
                }}
              >
                <Text style={[typography.headline, { color: colors.danger }]}>✕</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListEmptyComponent={
          !isLoading ? (
            <View style={{ padding: spacing.xl, alignItems: 'center' }}>
              <Text style={[typography.subheadline, { color: colors.textTertiary }]}>
                No items in grocery list
              </Text>
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
          padding: spacing.lg,
          backgroundColor: colors.surface,
          borderTopWidth: 1,
          borderTopColor: colors.border,
          gap: spacing.md,
        }}>
          <TextInput
            placeholder="Item name"
            value={name}
            onChangeText={setName}
            placeholderTextColor={colors.textTertiary}
            style={{
              borderWidth: 1,
              borderColor: colors.border,
              padding: spacing.md,
              borderRadius: radius.button,
              ...typography.body,
              color: colors.textPrimary,
              backgroundColor: colors.background,
            }}
          />
          <TextInput
            placeholder="Quantity (e.g., 2 cups)"
            value={quantity}
            onChangeText={setQuantity}
            placeholderTextColor={colors.textTertiary}
            style={{
              borderWidth: 1,
              borderColor: colors.border,
              padding: spacing.md,
              borderRadius: radius.button,
              ...typography.body,
              color: colors.textPrimary,
              backgroundColor: colors.background,
            }}
          />
          <TextInput
            placeholder="Note (optional)"
            value={note}
            onChangeText={setNote}
            placeholderTextColor={colors.textTertiary}
            style={{
              borderWidth: 1,
              borderColor: colors.border,
              padding: spacing.md,
              borderRadius: radius.button,
              ...typography.body,
              color: colors.textPrimary,
              backgroundColor: colors.background,
            }}
          />
          <CategoryPicker value={category} onChange={setCategory} />
          <View style={{ flexDirection: 'row', gap: spacing.sm }}>
            <TouchableOpacity
              onPress={handleAddItem}
              style={{
                flex: 1,
                backgroundColor: colors.primary,
                padding: spacing.md,
                borderRadius: radius.button,
                alignItems: 'center',
              }}
            >
              <Text style={[typography.headline, { color: colors.background }]}>
                Add Item
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setShowAddForm(false)}
              style={{
                flex: 1,
                backgroundColor: colors.border,
                padding: spacing.md,
                borderRadius: radius.button,
                alignItems: 'center',
              }}
            >
              <Text style={[typography.headline, { color: colors.textSecondary }]}>
                Cancel
              </Text>
            </TouchableOpacity>
          </View>
        </View>
      )}

      {!showAddForm && (
        <TouchableOpacity
          onPress={() => setShowAddForm(true)}
          style={{
            backgroundColor: colors.primary,
            padding: spacing.lg,
            margin: spacing.lg,
            borderRadius: radius.button,
            alignItems: 'center',
          }}
        >
          <Text style={[typography.headline, { color: colors.background }]}>
            + Add Item
          </Text>
        </TouchableOpacity>
      )}
    </View>
  )
}
