/**
 * Fixed service area for delivery / saved addresses (shop city, state, PIN).
 * Override per build with EXPO_PUBLIC_SHOP_CITY, EXPO_PUBLIC_SHOP_STATE, EXPO_PUBLIC_SHOP_PINCODE in `.env`.
 */
function read(key: string, fallback: string): string {
  const v = process.env[key];
  return typeof v === 'string' && v.trim() ? v.trim() : fallback;
}

export const SHOP_CITY = read('EXPO_PUBLIC_SHOP_CITY', 'Palakkad');
export const SHOP_STATE = read('EXPO_PUBLIC_SHOP_STATE', 'Kerala');
export const SHOP_PINCODE = read('EXPO_PUBLIC_SHOP_PINCODE', '678001');
