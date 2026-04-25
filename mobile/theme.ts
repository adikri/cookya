export const colors = {
  primary: '#007AFF',
  background: '#FFFFFF',
  surface: '#F2F2F7',
  border: '#E5E5EA',
  textPrimary: '#000000',
  textSecondary: '#6C6C70',
  textTertiary: '#AEAEB2',
  danger: '#FF3B30',
  warning: '#FF9500',
  success: '#34C759',
} as const

export const spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  xxl: 24,
} as const

export const radius = {
  card: 16,
  button: 10,
  chip: 100,
} as const

export const typography = {
  title2: { fontSize: 20, fontWeight: '700' as const },
  headline: { fontSize: 17, fontWeight: '600' as const },
  body: { fontSize: 17, fontWeight: '400' as const },
  subheadline: { fontSize: 15, fontWeight: '400' as const },
  caption: { fontSize: 13, fontWeight: '400' as const },
} as const
