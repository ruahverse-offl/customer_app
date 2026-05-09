import React from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { router } from 'expo-router';
import type { Href } from 'expo-router';

import { useNotifications } from '@/context/NotificationContext';
import { Theme } from '@/constants/theme';
import { HREF_PROFILE_SETTINGS } from '@/lib/navigation';

/**
 * Shows a compact prompt when notifications are denied.
 */
export function NotificationPermissionBanner() {
  const { loading, permissionGranted } = useNotifications();

  if (loading || permissionGranted) return null;

  return (
    <View style={styles.wrap}>
      <Text style={styles.text}>Enable notifications for order updates.</Text>
      <Pressable onPress={() => router.push(HREF_PROFILE_SETTINGS as Href)} hitSlop={8}>
        <Text style={styles.link}>Open settings</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    marginHorizontal: 16,
    marginTop: 10,
    marginBottom: 8,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#fde68a',
    backgroundColor: '#fffbeb',
    paddingVertical: 10,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 12,
  },
  text: { flex: 1, color: '#92400e', fontSize: 13, fontWeight: '600' },
  link: { color: Theme.primary, fontSize: 13, fontWeight: '800' },
});

