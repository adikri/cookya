import { useEffect, useState } from 'react'
import { View, FlatList, TouchableOpacity, Text, TextInput, Alert } from 'react-native'
import { usePantryStore } from '../../stores/pantryStore'
import { CategoryPicker } from '../../components/CategoryPicker'
import { colors, spacing, radius, typography } from '../../theme'

export default function PantryScreen() {
  const { items, fetchItems, addItem, deleteItem, isLoading, error } = usePantryStore()
  const [showAddForm, setShowAddForm] = useState(false)
  const [name, setName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [category, setCategory] = useState('vegetables')

  useEffect(() => {
    fetchItems()
  }, [])

  const handleAddItem = async () => {
    if (!name || !quantity) {
      Alert.alert('Error', 'Please fill in all fields')
      return
    }
    await addItem(name, quantity, category)
    setName('')
    setQuantity('')
    setCategory('vegetables')
    setShowAddForm(false)
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
            </View>
            <TouchableOpacity
              onPress={() => handleDelete(item.id)}
              style={{ padding: spacing.sm, marginLeft: spacing.md }}
            >
              <Text style={[typography.subheadline, { color: colors.danger, fontWeight: '600' }]}>
                Delete
              </Text>
            </TouchableOpacity>
          </View>
        )}
        ListEmptyComponent={
          !isLoading ? (
            <View style={{ padding: spacing.xl, alignItems: 'center' }}>
              <Text style={[typography.subheadline, { color: colors.textTertiary }]}>
                No items in pantry
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
              <Text style={[typography.headline, { color: colors.background }]}>Add Item</Text>
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
              <Text style={[typography.headline, { color: colors.textSecondary }]}>Cancel</Text>
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
          <Text style={[typography.headline, { color: colors.background }]}>+ Add Item</Text>
        </TouchableOpacity>
      )}
    </View>
  )
}
