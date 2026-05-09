/** Aligns with `new_balan_fe` `src/index.css` :root palette - EXACT MATCH */
export const Theme = {
  // Primary colors - Blue theme
  primary: '#0056b3',
  primaryDark: '#004085',
  primaryLight: '#e7f3ff',

  // Secondary colors - Green theme
  secondary: '#28a745',
  secondaryDark: '#1e7e34',
  secondaryLight: '#e8f5e9',

  // Accent
  accent: '#5bc0de',
  accentBlue: '#1d4ed8',

  // Base colors
  white: '#ffffff',

  // Gray scale
  gray50: '#f9fafb',
  gray100: '#f3f4f6',
  gray200: '#e5e7eb',
  gray300: '#d1d5db',
  gray400: '#9ca3af',
  gray500: '#6b7280',
  gray600: '#4b5563',
  gray700: '#374151',
  gray800: '#1f2937',
  gray900: '#111827',

  // Shadows
  shadow: 'rgba(0, 0, 0, 0.1)',
  shadowSm: 'rgba(0, 0, 0, 0.05)',
  shadowMd: 'rgba(0, 0, 0, 0.1)',
  shadowLg: 'rgba(0, 0, 0, 0.15)',

  // Gradients
  gradientHero: ['#0f172a', '#1d4ed8'] as const,
  gradientHeroSoft: ['#1e3a8a', '#2563eb'] as const,
  primaryGradient: ['#0056b3', '#003d82'] as const,
  secondaryGradient: ['#28a745', '#1e7e34'] as const,

  // Border radius
  radiusSm: 6,
  radiusMd: 8,
  radius: 8,
  radiusLg: 16,
  radiusXl: 20,
  radiusFull: 9999,

  // Card shadow — use on iOS; Android uses elevation in StyleSheet
  shadowCard: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },

  // Focus ring (for accessibility)
  focusRing: 'rgba(0, 86, 179, 0.45)',
} as const;

/** Loaded via `@expo-google-fonts/inter` / `outfit` in `app/_layout.tsx` */
export const Fonts = {
  body: 'Inter_400Regular',
  bodySemi: 'Inter_600SemiBold',
  heading: 'Outfit_700Bold',
  display: 'Outfit_800ExtraBold',
} as const;

export type ThemeColors = typeof Theme;
