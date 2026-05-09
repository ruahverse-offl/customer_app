import React from 'react';
import { Stack } from 'expo-router';

import { Theme } from '@/constants/theme';

/**
 * Nested stack: my profile, orders, addresses, change password, appointments.
 */
export default function ProfileGroupLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Theme.white },
        headerTintColor: Theme.gray900,
        headerTitleStyle: { fontWeight: '700' },
        headerShadowVisible: false,
        contentStyle: { backgroundColor: Theme.gray50 },
      }}>
      <Stack.Screen name="index" options={{ title: 'My profile' }} />
      <Stack.Screen name="orders" options={{ title: 'My orders' }} />
      <Stack.Screen name="addresses" options={{ title: 'My addresses' }} />
      <Stack.Screen name="settings" options={{ title: 'Settings' }} />
      <Stack.Screen name="change-password" options={{ title: 'Change password' }} />
      <Stack.Screen name="appointments" options={{ title: 'Appointments' }} />
    </Stack>
  );
}
