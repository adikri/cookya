import { useState } from 'react'
import { View, TextInput, TouchableOpacity, Text, Alert } from 'react-native'
import { Link } from 'expo-router'
import { useAuthStore } from '../../stores/authStore'

export default function SignUpScreen() {
  const { signUp, isLoading } = useAuthStore()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')

  const handleSignUp = async () => {
    if (!email || !password || !confirmPassword) {
      Alert.alert('Error', 'Please fill in all fields')
      return
    }
    if (password !== confirmPassword) {
      Alert.alert('Error', 'Passwords do not match')
      return
    }
    // authStore.signUp catches errors internally and stores them in state.error
    // (it never re-throws), so we read post-await state instead of try/catch.
    // On success, _layout.tsx auth guard detects isNewUser and navigates to profile tab.
    await signUp(email, password)
    const state = useAuthStore.getState()
    if (!state.isSignedIn) {
      Alert.alert('Sign up failed', state.error || 'Unknown error. Please try again.')
    }
  }

  return (
    <View style={{ flex: 1, justifyContent: 'center', padding: 20, backgroundColor: '#fff' }}>
      <Text style={{ fontSize: 28, fontWeight: 'bold', marginBottom: 30, textAlign: 'center' }}>
        Create Account
      </Text>

      <TextInput
        placeholder="Email"
        value={email}
        onChangeText={setEmail}
        autoCapitalize="none"
        keyboardType="email-address"
        placeholderTextColor="#999"
        style={{
          borderWidth: 1,
          borderColor: '#ddd',
          padding: 12,
          borderRadius: 8,
          marginBottom: 16,
        }}
      />

      <TextInput
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        placeholderTextColor="#999"
        style={{
          borderWidth: 1,
          borderColor: '#ddd',
          padding: 12,
          borderRadius: 8,
          marginBottom: 16,
        }}
      />

      <TextInput
        placeholder="Confirm Password"
        value={confirmPassword}
        onChangeText={setConfirmPassword}
        secureTextEntry
        placeholderTextColor="#999"
        style={{
          borderWidth: 1,
          borderColor: '#ddd',
          padding: 12,
          borderRadius: 8,
          marginBottom: 24,
        }}
      />

      <TouchableOpacity
        onPress={handleSignUp}
        disabled={isLoading}
        style={{
          backgroundColor: isLoading ? '#ccc' : '#007AFF',
          padding: 14,
          borderRadius: 8,
          marginBottom: 16,
        }}
      >
        <Text style={{ color: '#fff', fontSize: 16, fontWeight: '600', textAlign: 'center' }}>
          {isLoading ? 'Creating account...' : 'Sign Up'}
        </Text>
      </TouchableOpacity>

      <View style={{ flexDirection: 'row', justifyContent: 'center' }}>
        <Text style={{ color: '#666' }}>Already have an account? </Text>
        <Link href="/(auth)/sign-in">
          <Text style={{ color: '#007AFF', fontWeight: '600' }}>Sign In</Text>
        </Link>
      </View>
    </View>
  )
}
