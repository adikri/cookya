import { useEffect, useState } from 'react'
import { View, ScrollView, FlatList, TouchableOpacity, Text, TextInput, Alert } from 'react-native'
import { usePantryStore } from '../../stores/pantryStore'

export default function PantryScreen() {
  const { items, fetchItems, addItem, deleteItem, isLoading } = usePantryStore()
  const [showAddForm, setShowAddForm] = useState(false)
  const [name, setName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [category, setCategory] = useState('pantry')

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
    setCategory('pantry')
    setShowAddForm(false)
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
            </View>
            <TouchableOpacity
              onPress={() => handleDelete(item.id)}
              style={{ padding: 8, marginLeft: 12 }}
            >
              <Text style={{ color: '#FF3B30', fontWeight: '600' }}>Delete</Text>
            </TouchableOpacity>
          </View>
        )}
        ListEmptyComponent={
          !isLoading ? (
            <View style={{ padding: 20, alignItems: 'center' }}>
              <Text style={{ color: '#999' }}>No items in pantry</Text>
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
