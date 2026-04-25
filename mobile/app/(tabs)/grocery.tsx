import { useEffect, useState } from 'react'
import { View, FlatList, TouchableOpacity, Text, TextInput, Alert } from 'react-native'
import { useGroceryStore } from '../../stores/groceryStore'

export default function GroceryScreen() {
  const { items, fetchItems, addItem, markPurchased, deleteItem, isLoading } = useGroceryStore()
  const [showAddForm, setShowAddForm] = useState(false)
  const [name, setName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [category, setCategory] = useState('pantry')
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
    setCategory('pantry')
    setNote('')
    setShowAddForm(false)
  }

  const handlePurchased = (id: string, item: any) => {
    Alert.alert('Mark as purchased?', '', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Mark Purchased',
        onPress: () => markPurchased(id, item),
        style: 'default',
      },
    ])
  }

  const handleDelete = (id: string) => {
    Alert.alert('Delete item?', '', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete', onPress: () => deleteItem(id), style: 'destructive' },
    ])
  }

  return (
    <View style={{ flex: 1, backgroundColor: '#fff' }}>
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <View
            style={{
              flexDirection: 'row',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: 16,
              borderBottomWidth: 1,
              borderBottomColor: '#eee',
            }}
          >
            <View style={{ flex: 1 }}>
              <Text style={{ fontSize: 16, fontWeight: '600' }}>{item.name}</Text>
              <Text style={{ color: '#666', fontSize: 14 }}>
                {item.quantity_text} • {item.category}
              </Text>
              {item.note && (
                <Text style={{ color: '#999', fontSize: 12, marginTop: 4 }}>
                  Note: {item.note}
                </Text>
              )}
            </View>
            <View style={{ flexDirection: 'row', gap: 8, marginLeft: 12 }}>
              <TouchableOpacity
                onPress={() => handlePurchased(item.id, item)}
                style={{ padding: 8 }}
              >
                <Text style={{ color: '#007AFF', fontWeight: '600' }}>✓</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={() => handleDelete(item.id)}
                style={{ padding: 8 }}
              >
                <Text style={{ color: '#FF3B30', fontWeight: '600' }}>✕</Text>
              </TouchableOpacity>
            </View>
          </View>
        )}
        ListEmptyComponent={
          !isLoading ? (
            <View style={{ padding: 20, alignItems: 'center' }}>
              <Text style={{ color: '#999' }}>No items in grocery list</Text>
            </View>
          ) : null
        }
      />

      {showAddForm && (
        <View
          style={{
            padding: 16,
            backgroundColor: '#f5f5f5',
            borderTopWidth: 1,
            borderTopColor: '#ddd',
          }}
        >
          <TextInput
            placeholder="Item name"
            value={name}
            onChangeText={setName}
            placeholderTextColor="#999"
            style={{
              borderWidth: 1,
              borderColor: '#ddd',
              padding: 12,
              borderRadius: 8,
              marginBottom: 12,
            }}
          />
          <TextInput
            placeholder="Quantity (e.g., 2 cups)"
            value={quantity}
            onChangeText={setQuantity}
            placeholderTextColor="#999"
            style={{
              borderWidth: 1,
              borderColor: '#ddd',
              padding: 12,
              borderRadius: 8,
              marginBottom: 12,
            }}
          />
          <TextInput
            placeholder="Note (optional)"
            value={note}
            onChangeText={setNote}
            placeholderTextColor="#999"
            style={{
              borderWidth: 1,
              borderColor: '#ddd',
              padding: 12,
              borderRadius: 8,
              marginBottom: 12,
            }}
          />
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <TouchableOpacity
              onPress={handleAddItem}
              style={{
                flex: 1,
                backgroundColor: '#007AFF',
                padding: 12,
                borderRadius: 8,
              }}
            >
              <Text style={{ color: '#fff', fontWeight: '600', textAlign: 'center' }}>
                Add Item
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => setShowAddForm(false)}
              style={{
                flex: 1,
                backgroundColor: '#ccc',
                padding: 12,
                borderRadius: 8,
              }}
            >
              <Text style={{ color: '#fff', fontWeight: '600', textAlign: 'center' }}>
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
            backgroundColor: '#007AFF',
            padding: 16,
            margin: 16,
            borderRadius: 8,
          }}
        >
          <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', textAlign: 'center' }}>
            + Add Item
          </Text>
        </TouchableOpacity>
      )}
    </View>
  )
}
