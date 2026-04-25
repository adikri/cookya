import { useEffect } from 'react'
import { Stack, useRouter, useSegments } from 'expo-router'
import { View, ActivityIndicator } from 'react-native'
import { useAuthStore } from '../stores/authStore'

export default function RootLayout() {
  const { isLoading, isSignedIn, checkSession } = useAuthStore()
  const router = useRouter()
  const segments = useSegments()

  useEffect(() => {
    checkSession()
  }, [])

  useEffect(() => {
    if (isLoading) return
    const inAuthGroup = segments[0] === '(auth)'
    if (!isSignedIn && !inAuthGroup) {
      router.replace('/(auth)/sign-in')
    } else if (isSignedIn && inAuthGroup) {
      router.replace('/(tabs)')
    }
  }, [isSignedIn, isLoading, segments])

  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#fff' }}>
        <ActivityIndicator size="large" color="#007AFF" />
      </View>
    )
  }

  return <Stack screenOptions={{ headerShown: false }} />
}
