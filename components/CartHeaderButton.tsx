import React, { useMemo } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import FontAwesome from '@expo/vector-icons/FontAwesome';
import { router } from 'expo-router';
import type { Href } from 'expo-router';

import { Theme } from '@/constants/theme';
import { useCart } from '@/context/CartContext';
import { HREF_CHECKOUT } from '@/lib/navigation';

/**
 * Header bag control: total item count, navigates to checkout tab.
 */
export default function CartHeaderButton() {
  const { cart } = useCart();
  const count = useMemo(() => cart.reduce((sum, line) => sum + (line.quantity || 0), 0), [cart]);

  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={count ? `Cart, ${count} items` : 'Cart, empty'}
      onPress={() => router.navigate(HREF_CHECKOUT)}
      style={styles.wrap}
      hitSlop={12}>
      <FontAwesome name="shopping-bag" size={20} color={Theme.gray900} />
      {count > 0 ? (
        <View style={styles.badge}>
          <Text style={styles.badgeText}>{count > 99 ? '99+' : String(count)}</Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrap: { marginRight: 4, paddingVertical: 6, paddingHorizontal: 10, justifyContent: 'center', alignItems: 'center' },
  badge: {
    position: 'absolute',
    top: 0,
    right: 2,
    minWidth: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: Theme.accentBlue,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 4,
    borderWidth: 2,
    borderColor: Theme.white,
  },
  badgeText: { color: Theme.white, fontSize: 10, fontWeight: '800' },
});
