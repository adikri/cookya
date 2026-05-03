/**
 * Generates a UUID v4 string for database row identifiers.
 *
 * Why this exists: React Native's JS runtime does not expose the Web Crypto
 * API, so `crypto.randomUUID()` throws "Property 'crypto' doesn't exist" on
 * iOS and Android. Adding `expo-crypto` would solve it but requires a native
 * rebuild every time the package is bumped.
 *
 * Trade-off: this uses `Math.random`, which is NOT cryptographically secure.
 * That is fine for our use case — these IDs only identify database rows, and
 * Supabase Row Level Security is the actual security boundary. Collision
 * probability across UUID v4 space at our scale is effectively zero.
 *
 * Do NOT use this for tokens, session IDs, or anything security-sensitive.
 */
export function generateId(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === 'x' ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}
